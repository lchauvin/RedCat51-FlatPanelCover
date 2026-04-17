// ============================================================
//  LED PWM test — RedCat 51 Flat Panel prototype
//
//  Wiring:
//    Arduino pin 9 ──[470Ω]──┬──► MOSFET Gate (IRLZ44N)
//                             │
//                           [10kΩ]
//                             │
//    Arduino GND ─────────────┴── MOSFET Source ── GND rail
//    Arduino 5V  ─────────────────────────────────  +5V rail
//    +5V rail ──► LED strip (+)
//    LED strip (−) ──► MOSFET Drain
//    100µF cap across +5V rail and GND rail
//
//  Usage:
//    Auto-fade runs on startup.
//    Open Serial Monitor (9600 baud), type 0–255, press Enter
//    to hold a fixed brightness.  Press Enter with no value to
//    resume auto-fade.
// ============================================================

const int LED_PIN = 9;   // PWM pin — Arduino Mega supports PWM on 2,3,4,5,6,7,8,9,10,11,12,13

bool autoFade = true;

void setup() {
    pinMode(LED_PIN, OUTPUT);
    analogWrite(LED_PIN, 0);   // ensure strip is OFF on boot

    Serial.begin(9600);
    Serial.println("=== LED PWM test ===");
    Serial.println("Auto-fade running. Type 0-255 + Enter to set brightness.");
    Serial.println("Type Enter alone to resume auto-fade.");
}

void loop() {
    // ── Check for incoming serial command ──────────────────────
    if (Serial.available()) {
        String input = Serial.readStringUntil('\n');
        input.trim();

        if (input.length() == 0) {
            // Empty line → resume auto-fade
            autoFade = true;
            Serial.println("Auto-fade resumed.");
        } else {
            int val = input.toInt();
            val = constrain(val, 0, 255);
            analogWrite(LED_PIN, val);
            autoFade = false;
            Serial.print("Brightness: ");
            Serial.print(val);
            Serial.print(" / 255  (");
            Serial.print(val * 100 / 255);
            Serial.println("%)");
        }
        return;
    }

    // ── Auto-fade ──────────────────────────────────────────────
    if (autoFade) {
        // Ramp up 0 → 255
        for (int b = 0; b <= 255; b += 3) {
            if (Serial.available()) return;
            analogWrite(LED_PIN, b);
            delay(20);
        }
        delay(300);

        // Ramp down 255 → 0
        for (int b = 255; b >= 0; b -= 3) {
            if (Serial.available()) return;
            analogWrite(LED_PIN, b);
            delay(20);
        }
        delay(500);
    }
}
