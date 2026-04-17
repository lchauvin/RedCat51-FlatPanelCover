/*
 * RedCat 51 Flat Panel Firmware
 * Arduino Mega 2560
 *
 * Features:
 *   - 25 kHz PWM on pin 11 (Timer1 OC1A, 16-bit) — 640 brightness steps,
 *     eliminates flat-frame banding from camera rolling shutter.
 *   - 28BYJ-48 stepper on pins 22/24/26/28 via ULN2003 — 270° motorised cover
 *     Self-locking gears hold the cover against wind even when unpowered.
 *
 * Wiring:
 *   Pin 11 (OC1A) → 470Ω → IRLZ44N Gate (10kΩ pull-down Gate→GND)
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
static const uint8_t LED_PIN = 11;  // OC1A — Timer1 25 kHz PWM (16-bit, 640 steps)

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

// ── Brightness range ────────────────────────────────────────────────────────
// Timer1 at 25 kHz with prescaler=1: TOP = 16 MHz / 25 000 = 640 counts.
// External brightness range is 0-640 (reported as maxbrightness to Alpaca).
static const uint16_t MAX_BRIGHTNESS = 640;

// ── Device identity ─────────────────────────────────────────────────────────
static const char* DEVICE_GUID = "A1B2C3D4-E5F6-7890-ABCD-EF1234567890";
static const char* DEVICE_INFO = "RedCat51FlatPanel v1.0";

// ── State ───────────────────────────────────────────────────────────────────
enum CoverState { COVER_OPEN = 0, COVER_CLOSED = 1, COVER_MOVING = 2 };

// Correct step sequence for 28BYJ-48: IN1, IN3, IN2, IN4
Stepper coverStepper(STEPS_PER_REV, STEP_IN1, STEP_IN3, STEP_IN2, STEP_IN4);

uint16_t   ledBrightness = 0;
bool       ledOn         = false;
CoverState coverState    = COVER_CLOSED;
int        stepPosition  = 0;   // current step position (0 = closed)
String     inputBuffer;

// ── 25 kHz PWM setup (Timer1 OC1A = pin 11) ────────────────────────────────
// Timer1 Fast PWM mode 14 (WGM13:0 = 1110), ICR1 as TOP, prescaler = 1.
// f_pwm = 16 MHz / (1 × 640) = 25 000 Hz
// OCR1A range: 0 (0 % duty) … ≥640 (100 % duty, compare never fires)
void setupPWM25kHz() {
    pinMode(LED_PIN, OUTPUT);
    // COM1A1=1, COM1A0=0: clear OC1A on compare match, set at BOTTOM (non-inverting)
    // WGM11=1, WGM10=0: part of mode 14
    TCCR1A = _BV(COM1A1) | _BV(WGM11);
    // WGM13=1, WGM12=1: ICR1 as TOP; CS10=1: prescaler = 1
    TCCR1B = _BV(WGM13) | _BV(WGM12) | _BV(CS10);
    ICR1  = 639;   // TOP = 640 counts → 25 kHz
    OCR1A = 0;     // duty → 0 %
}

// Set LED brightness (0 = off … 640 = 100 % duty).
// brightness=0: disconnect OC1A and drive LOW — avoids the 1-cycle hardware
//   glitch pulse that keeps LEDs faintly lit at OCR1A=0 in fast PWM mode.
// brightness≥640: OCR1A > ICR1 → compare never fires → true 100 % duty.
void setLEDDuty(uint16_t brightness) {
    if (brightness == 0) {
        TCCR1A &= ~_BV(COM1A1);   // disconnect OC1A from timer output
        digitalWrite(LED_PIN, LOW);
    } else {
        TCCR1A |= _BV(COM1A1);    // reconnect OC1A to timer output
        OCR1A = (brightness >= MAX_BRIGHTNESS) ? MAX_BRIGHTNESS : brightness;
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
        val = constrain(val, 0, (int)MAX_BRIGHTNESS);
        ledBrightness = (uint16_t)val;
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
