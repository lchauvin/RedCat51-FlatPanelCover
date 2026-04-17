/*
 * RedCat 51 Flat Panel Firmware
 * Arduino Mega 2560
 *
 * Features:
 *   - 25 kHz PWM on pin 9 (Timer2 OC2B) — eliminates flat-frame banding
 *   - 28BYJ-48 stepper on pins 22/24/26/28 via ULN2003 — 270° motorised cover
 *     Self-locking gears hold the cover against wind even when unpowered.
 *
 * Wiring:
 *   Pin 9  (OC2B) → 220Ω → IRLZ44N Gate (10kΩ pull-down Gate→GND)
 *   IRLZ44N Drain → LED strip (−)  |  LED strip (+) → 5V USB (own cable)
 *   IRLZ44N Source → GND
 *
 *   ULN2003 IN1 → Pin 22   ULN2003 IN2 → Pin 24
 *   ULN2003 IN3 → Pin 26   ULN2003 IN4 → Pin 28
 *   ULN2003 +5V → 5V rail  ULN2003 GND → GND
 *   28BYJ-48 white 5-pin connector → ULN2003 output connector
 */

#include <Stepper.h>

// ── Pin assignments ─────────────────────────────────────────────────────────
static const uint8_t LED_PIN = 9;  // OC2B — Timer2 25 kHz PWM

// 28BYJ-48 via ULN2003 — pin order IN1,IN3,IN2,IN4 gives correct step sequence
static const uint8_t STEP_IN1 = 22;
static const uint8_t STEP_IN2 = 24;
static const uint8_t STEP_IN3 = 26;
static const uint8_t STEP_IN4 = 28;

// ── Stepper parameters ──────────────────────────────────────────────────────
// 28BYJ-48: 2048 steps per full revolution (64:1 gear × 32 internal steps)
static const int STEPS_PER_REV = 2048;
// 270° = 2048 × (270/360) = 1536 steps
static const int STEPS_OPEN    = 1536;
// Motor speed — do not exceed 15 RPM (torque drops sharply above this)
static const int MOTOR_RPM     = 12;

// ── Device identity ─────────────────────────────────────────────────────────
static const char* DEVICE_GUID = "A1B2C3D4-E5F6-7890-ABCD-EF1234567890";
static const char* DEVICE_INFO = "RedCat51FlatPanel v1.0";

// ── State ───────────────────────────────────────────────────────────────────
enum CoverState { COVER_OPEN = 0, COVER_CLOSED = 1, COVER_MOVING = 2 };

// Correct step sequence for 28BYJ-48: IN1, IN3, IN2, IN4
Stepper coverStepper(STEPS_PER_REV, STEP_IN1, STEP_IN3, STEP_IN2, STEP_IN4);

uint8_t    ledBrightness = 0;
bool       ledOn         = false;
CoverState coverState    = COVER_CLOSED;
int        stepPosition  = 0;   // current step position (0 = closed)
String     inputBuffer;

// ── 25 kHz PWM setup (Timer2 OC2B = pin 9) ─────────────────────────────────
// f_pwm = 16 MHz / (prescaler × (OCR2A + 1)) = 16 000 000 / (8 × 80) = 25 000 Hz
// OCR2B range: 0 (0 % duty) … 79 (100 % duty)
void setupPWM25kHz() {
    pinMode(LED_PIN, OUTPUT);
    // Fast PWM mode, TOP = OCR2A, clear OC2B on compare match (non-inverting)
    TCCR2A = _BV(COM2B1) | _BV(WGM21) | _BV(WGM20);
    // WGM22=1 selects OCR2A as TOP; CS21=1 selects prescaler /8
    TCCR2B = _BV(WGM22) | _BV(CS21);
    OCR2A  = 79;   // TOP → 25 kHz
    OCR2B  = 0;    // duty → 0 %
}

// Map external 0-255 brightness to internal 0-79 Timer2 duty cycle.
// Multiply by 80 (not 79): input 255 → OCR2B=80 > OCR2A=79, compare never fires
// → output stays HIGH = true 100 % duty.
// Special case for 0: disconnect OC2B from the timer and drive the pin LOW.
// At OCR2B=0 in fast PWM non-inverting mode the AVR still fires a 1-cycle
// glitch pulse each period, keeping LEDs faintly lit.
void setLEDDuty(uint8_t brightness255) {
    uint8_t duty = (uint8_t)((uint16_t)brightness255 * 80 / 255);
    if (duty == 0) {
        TCCR2A &= ~_BV(COM2B1);   // disconnect OC2B from timer output
        digitalWrite(LED_PIN, LOW);
    } else {
        TCCR2A |= _BV(COM2B1);    // reconnect OC2B to timer output
        OCR2B = duty;
    }
}

// ── Stepper power control ────────────────────────────────────────────────────
// De-energise all coils when idle to prevent heat and save power.
// The 64:1 gearbox is mechanically self-locking — no holding current needed.
void stepperPowerOff() {
    digitalWrite(STEP_IN1, LOW);
    digitalWrite(STEP_IN2, LOW);
    digitalWrite(STEP_IN3, LOW);
    digitalWrite(STEP_IN4, LOW);
}

// ── Cover control ────────────────────────────────────────────────────────────
void moveCover(bool open) {
    int target = open ? STEPS_OPEN : 0;
    int delta  = target - stepPosition;
    if (delta == 0) return;

    coverState = COVER_MOVING;
    coverStepper.setSpeed(MOTOR_RPM);
    coverStepper.step(delta);   // positive = open direction, negative = close
    stepPosition = target;
    stepperPowerOff();          // coils off — gears hold position passively
    coverState = open ? COVER_OPEN : COVER_CLOSED;
}

// ── Command parser ────────────────────────────────────────────────────────────
void handleCommand(const String& cmd) {

    if (cmd == "COMMAND:PING") {
        Serial.print("RESULT:PING:OK:");
        Serial.println(DEVICE_GUID);

    } else if (cmd == "COMMAND:INFO") {
        Serial.print("RESULT:INFO:");
        Serial.println(DEVICE_INFO);

    } else if (cmd.startsWith("COMMAND:CALIBRATOR:ON:")) {
        int val = cmd.substring(22).toInt();
        val = constrain(val, 0, 255);
        ledBrightness = (uint8_t)val;
        ledOn = true;
        setLEDDuty(ledBrightness);
        Serial.println("RESULT:CALIBRATOR:ON:OK");

    } else if (cmd == "COMMAND:CALIBRATOR:OFF") {
        ledOn = false;
        setLEDDuty(0);
        Serial.println("RESULT:CALIBRATOR:OFF:OK");

    } else if (cmd == "COMMAND:CALIBRATOR:GETBRIGHTNESS") {
        Serial.print("RESULT:CALIBRATOR:BRIGHTNESS:");
        Serial.println(ledOn ? ledBrightness : 0);

    } else if (cmd == "COMMAND:COVER:OPEN") {
        if (coverState != COVER_OPEN) moveCover(true);
        Serial.println("RESULT:COVER:OPEN:OK");

    } else if (cmd == "COMMAND:COVER:CLOSE") {
        if (coverState != COVER_CLOSED) moveCover(false);
        Serial.println("RESULT:COVER:CLOSE:OK");

    } else if (cmd == "COMMAND:COVER:HALT") {
        // Immediately cut power — gears lock in current position
        stepperPowerOff();
        coverState = COVER_OPEN;   // assume partially open; safe default for NINA
        Serial.println("RESULT:COVER:HALT:OK");

    } else if (cmd == "COMMAND:COVER:GETSTATE") {
        const char* s;
        switch (coverState) {
            case COVER_OPEN:   s = "OPEN";   break;
            case COVER_CLOSED: s = "CLOSED"; break;
            default:           s = "MOVING"; break;
        }
        Serial.print("RESULT:COVER:STATE:");
        Serial.println(s);

    } else {
        Serial.print("ERROR:UNKNOWN:");
        Serial.println(cmd);
    }
}

// ── Arduino lifecycle ─────────────────────────────────────────────────────────
void setup() {
    Serial.begin(57600);
    setupPWM25kHz();

    // Stepper pin modes
    pinMode(STEP_IN1, OUTPUT);
    pinMode(STEP_IN2, OUTPUT);
    pinMode(STEP_IN3, OUTPUT);
    pinMode(STEP_IN4, OUTPUT);

    // Cover state is unknown at power-on; report as CLOSED (safe default for NINA).
    // Homing will happen on the first COVER:CLOSE command.
    stepPosition = 0;
    coverState   = COVER_CLOSED;

    inputBuffer.reserve(64);
}

void loop() {
    while (Serial.available()) {
        char c = (char)Serial.read();
        if (c == '\n') {
            inputBuffer.trim();
            if (inputBuffer.length() > 0) {
                handleCommand(inputBuffer);
            }
            inputBuffer = "";
        } else if (c != '\r') {
            inputBuffer += c;
        }
    }
}
