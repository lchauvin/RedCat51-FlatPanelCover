// LED PWM test — flat panel prototype
// Fades a 5V LED strip up and down using PWM on pin 9.
// Type a number 0-255 in Serial Monitor to hold a fixed brightness.

const int LED_PIN = 9;
bool autoFade = true;

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
// Special case for 0: disconnect OC2B from the timer and drive the pin
// LOW directly.  At OCR2B = 0 in fast PWM non-inverting mode the AVR
// still fires a 1-cycle glitch pulse each period, keeping LEDs faintly lit.
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

void setup() {
    //pinMode(LED_PIN, OUTPUT);
    //analogWrite(LED_PIN, 0);
    Serial.begin(9600);
    //Serial.println("LED PWM test ready. Type 0-255 + Enter to set brightness.");
    //Serial.begin(57600);
    setupPWM25kHz();
}

// Call this frequently — reads one line if available, sets brightness.
void checkSerial() {
    if (!Serial.available()) return;

    String input = Serial.readStringUntil('\n');  // reads full line, consumes the \n
    input.trim();                                  // removes \r and spaces
    if (input.length() == 0) return;

    int val = constrain(input.toInt(), 0, 255);
    //analogWrite(LED_PIN, val);
    setLEDDuty(val);
    autoFade = false;
    Serial.print("Brightness: ");
    Serial.print(val);
    Serial.println(" / 255");
}

void loop() {
    checkSerial();

    if (!autoFade) return;   // holding a fixed brightness — do nothing

    // Auto-fade: ramp up
    for (int b = 0; b <= 255; b += 5) {
        checkSerial();
        if (!autoFade) return;
        setLEDDuty(b);
        delay(30);
    }
    // Auto-fade: ramp down
    for (int b = 255; b >= 0; b -= 5) {
        checkSerial();
        if (!autoFade) return;
        setLEDDuty(b);
        delay(30);
    }
    delay(500);
}
