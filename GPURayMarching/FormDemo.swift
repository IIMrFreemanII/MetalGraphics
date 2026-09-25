import Foundation
import MetalGraphicsLib
import ReactiveUI

enum Theme: Hashable {
  case system
  case light
  case dark
}

struct AudioSettings {
  var volume: Double = 0.6
  var muted: Bool = false
}

// Form, Section and the controls, as in SwiftUI.
//
// - Every control is bound with `$state`, lowered at compile time: the state's update sets the
//   control, and the control's change writes the state. The summary rows read the same states,
//   so both directions show.
// - `$audio.volume` and `$audio.muted` bind members of one state.
// - Tab moves between the text fields; Return in "Name" submits it.
// - "Reset" is disabled until something changed.
// - The first rows sit straight in the form, outside any section: they get a card of their own.
// - "Account" has view-valued header and footer; the footer's warning is a branch.
// - Pickers default to a menu; Difficulty is segmented, Theme a menu.
// - Dates open a calendar or time steppers in a popover; Start shows the calendar inline.
// - The tint opens a colour popover; the preview row follows it.
@Component
final class FormDemo : SingleChildElement {
  private static let size = float2(560, 640)

  @State var name: String = ""
  @State var password: String = ""
  @State var submitted: String = "nothing yet"
  @State var online: Bool = true
  @State var difficulty: Int = 1
  @State var theme: Theme = .system
  @State var audio: AudioSettings = AudioSettings()
  @State var lives: Int = 3
  @State var advanced: Bool = false
  @State var debug: Bool = false
  @State var verbose: Bool = false
  @State var notifications: Bool = true
  @State var due: Date = Date().addingTimeInterval(3 * 24 * 3600)
  @State var start: Date = Date()
  @State var tint: float4 = float4(0.0, 0.48, 1.0, 1)

  @UIElementBuilder var body: [UIElement] {
    Form {
      LabeledContent("Signed in as", value: self.name.isEmpty ? "Guest" : self.name)
      Toggle("Notifications", isOn: $notifications)
      Section {
        TextField("Name", text: $name, prompt: "Required")
          .onSubmit { self.submitted = self.name }
        SecureField("Password", text: $password, prompt: "At least 8 characters")
        Toggle("Show online status", isOn: $online)
      } header: {
        Text("Account")
      } footer: {
        Text("Your name is shown to other players.")
        if self.password.count > 0 && self.password.count < 8 {
          Text("The password is too short.").foregroundColor(float4(0.92, 0.23, 0.2, 1))
        }
      }
      Section("Game") {
        Picker("Difficulty", selection: $difficulty) {
          Text("Easy").tag(0)
          Text("Normal").tag(1)
          Text("Hard").tag(2)
        }
        .pickerStyle(.segmented)
        Stepper("Lives: \(self.lives)", value: $lives, in: 1 ... 9)
        Picker("Theme", selection: $theme) {
          Text("System").tag(Theme.system)
          Text("Light").tag(Theme.light)
          Text("Dark").tag(Theme.dark)
        }
      }
      Section("Schedule") {
        DatePicker("Due", selection: $due)
        DatePicker("Start", selection: $start, displayedComponents: .date)
          .datePickerStyle(.graphical)
      }
      Section("Appearance") {
        ColorPicker("Tint", selection: $tint)
        LabeledContent("Preview") {
          Rectangle(self.tint).frame(width: 64, height: 18).cornerRadius(4)
        }
      }
      Section("Audio") {
        Slider("Volume", value: $audio.volume, in: 0 ... 1)
        Toggle("Mute", isOn: $audio.muted)
        ProgressView(value: self.audio.muted ? 0 : self.audio.volume)
        DisclosureGroup("Advanced", isExpanded: $advanced) {
          Toggle("Debug overlay", isOn: $debug)
          Toggle("Verbose logging", isOn: $verbose)
          Toggle("Locked", isOn: .constant(true))
        }
      }
      Section("Summary") {
        LabeledContent("Player", value: self.name.isEmpty ? "—" : self.name)
        LabeledContent("Submitted", value: self.submitted)
        LabeledContent("Settings", value: "\(Self.difficultyName(self.difficulty)), \(self.lives) lives, \(Self.percent(self.audio))")
        LabeledContent("Due", value: self.due.formatted(date: .abbreviated, time: .shortened))
        if self.debug {
          LabeledContent("Debug", value: "password has \(self.password.count) characters")
        }
      }
      Section {
        Button("Reset", role: .destructive) { self.reset() }
          .disabled(self.name.isEmpty && self.password.isEmpty && self.lives == 3 && self.difficulty == 1)
      }
    }
    .frame(width: Self.size.x, height: Self.size.y)
  }

  // MARK: - Actions

  func reset() {
    self.name = ""
    self.password = ""
    self.submitted = "nothing yet"
    self.difficulty = 1
    self.lives = 3
  }

  private static func difficultyName(_ level: Int) -> String {
    switch level {
    case 0: "easy"
    case 2: "hard"
    default: "normal"
    }
  }

  private static func percent(_ audio: AudioSettings) -> String {
    audio.muted ? "muted" : "volume \(Int((audio.volume * 100).rounded()))%"
  }
}
