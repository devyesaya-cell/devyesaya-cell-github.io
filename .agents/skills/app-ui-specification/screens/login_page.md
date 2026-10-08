# Auth: Login Page
Path: `lib/features/auth/login_page.dart`

The entry point for operators to authenticate and initialize the Excavator Guidance System.

## Dependencies
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/state/auth_state.dart';       // AuthNotifier, AuthState, SystemMode enum
import '../../core/repositories/app_repository.dart'; // appRepositoryProvider
import '../../core/models/person.dart';            // Person Isar model
import '../../core/services/notification_service.dart'; // NotificationService.showError / showSuccess
import '../../core/coms/com_service.dart';         // comServiceProvider (USB state)
import '../../core/utils/app_theme.dart';          // AppTheme.of(context), AppThemeData
```

## Widget Type
`ConsumerStatefulWidget` → `_LoginPageState extends ConsumerState<LoginPage>`

## Local State Variables
| Variable              | Type                     | Default              | Purpose                                                  |
|-----------------------|--------------------------|----------------------|----------------------------------------------------------|
| `_selectedPerson`     | `Person?`                | `null`               | Currently selected operator from the dropdown            |
| `_persons`            | `List<Person>`           | `[]`                 | All person records fetched from Isar                     |
| `_selectedMode`       | `SystemMode`             | `SystemMode.spot`    | The operating mode chosen before login                   |
| `_passwordController` | `TextEditingController`  | `TextEditingController()` | Controls the access code text field               |
| `_obscureText`        | `bool`                   | `true`               | Toggles password visibility                              |

## Initialization (`initState` → `_initData`)
```
1. Read `appRepositoryProvider` from ref.
2. Call `repo.checkAndSeedDefaultUser()` — ensures at least one default Person exists in Isar on first run.
3. Call `repo.getAllPersons()` — fetches the complete Person list.
4. If widget is still mounted:
   - Set `_persons` to the fetched list.
   - Auto-select the first Person if the list is not empty.
```

---

## UI Structure (Full Layout Blueprint)

### Root: `Scaffold` → `Stack`
The Scaffold has no AppBar. The body is a `Stack` with three layers:

#### Layer 1 — Background Image
```dart
Positioned.fill(
  child: Image.asset('images/login_bg.jpeg', fit: BoxFit.cover),
)
```

#### Layer 2 — Overlay
```dart
Positioned.fill(
  child: Container(
    color: Colors.black.withValues(alpha: theme.overlayOpacity),
    // Dark mode: overlayOpacity = 0.40
    // Light mode: overlayOpacity = 0.15
  ),
)
```

#### Layer 3 — Main Content (`Row`)
A horizontal `Row` splitting the screen into two `Expanded` panels.

#### Layer 4 — Help Button (Floating)
```dart
Positioned(
  bottom: 32, right: 32,
  child: Container(
    padding: EdgeInsets.all(8),
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white54),
    ),
    child: Icon(Icons.help_outline, color: Colors.white54),
  ),
)
```

---

### Left Panel — Branding (`Expanded flex: 5`)
A `Container` with `padding: EdgeInsets.all(48.0)` containing a `Column(crossAxisAlignment: CrossAxisAlignment.start)`:

#### 1. Logo Badge (Top)
```
Container:
  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8)
  decoration:
    color: theme.logoBadgeBackground
      (Dark: Color(0x99000000), Light: Color(0xCCFFFFFF))
    borderRadius: 12
    border: Border.all(color: theme.logoBadgeBorder, width: 1)
      (Both: Color(0xFF00BCD4))
  child: Row(mainAxisSize: MainAxisSize.min)
    - Image.asset('images/logoToho.png', height: 32)
    - SizedBox(width: 12)
    - Column(crossAxisAlignment: start, mainAxisSize: min):
        Text 'TOHO EGS'
          color: isDark ? Colors.white : Color(0xFF3E2723)
          fontSize: 20, fontWeight: bold
        Text 'EXCAVATOR GUIDANCE SYSTEM'
          color: theme.labelColor
          fontSize: 10, letterSpacing: 1.2
```

#### 2. Spacer
`const Spacer()` — pushes the hero text and footer to the bottom.

#### 3. Hero Text
```
Text 'Ready for\nOperation.'
  color: Colors.white (always white, not themed)
  fontSize: 56, fontWeight: bold, height: 1.1
SizedBox(height: 24)
Text 'System diagnostics complete.\nPlease identify to unlock controls.'
  color: Colors.white70 (always white70, not themed)
  fontSize: 18, height: 1.5
```

#### 4. Footer Badge
```
SizedBox(height: 48)
Container:
  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6)
  color: Colors.black54
  child: Text 'POWERED BY   TOHO MITRA PRESISI'
    color: Colors.white54, fontSize: 10, fontWeight: bold
```

---

### Right Panel — Login Form (`Expanded flex: 4`)
Centered via `Center` → `Container`:

#### Form Card Container
```
Container:
  margin: EdgeInsets.only(right: 48)
  padding: EdgeInsets.all(32)
  constraints: BoxConstraints(maxWidth: 480)
  decoration:
    color: theme.cardBackground.withValues(alpha: isDark ? 0.95 : 0.97)
    borderRadius: 24
    border: Border.all(color: theme.cardBorder)
    boxShadow:
      color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.15)
      blurRadius: 20, offset: Offset(0, 10)
```

#### Form Card Content — `Column(mainAxisSize: min, crossAxisAlignment: stretch)`

##### A. Title Section
```
Text 'Operator Login'
  color: theme.titleColor, fontSize: 24, fontWeight: bold
SizedBox(height: 8)
Text 'Access level: Forestry Management'
  color: theme.subtitleColor, fontSize: 14
SizedBox(height: 32)
```

##### B. Operator Selection
```
Label: _buildLabel('SELECT OPERATOR', theme)
SizedBox(height: 8)
Container:
  padding: EdgeInsets.symmetric(horizontal: 16)
  decoration:
    color: theme.inputFill
    borderRadius: 12
    border: Border.all(color: theme.inputBorder)
  child: DropdownButtonHideUnderline → DropdownButton<Person>
    value: _selectedPerson
    hint: Text('Choose operator name', style: color: theme.dropdownHintText)
    dropdownColor: theme.dropdownBackground
    icon: Icon(Icons.expand_more, color: theme.dropdownIcon)
    style: TextStyle(color: theme.dropdownItemText)
    isExpanded: true
    items: _persons mapped to DropdownMenuItem
      display: '${p.firstName} ${p.lastName ?? ""}'
    onChanged: setState(() => _selectedPerson = val)
SizedBox(height: 24)
```

##### C. Access Code (Password)
```
Label: _buildLabel('ACCESS CODE', theme)
SizedBox(height: 8)
TextField:
  controller: _passwordController
  obscureText: _obscureText
  style: TextStyle(color: theme.inputTextColor)
  decoration:
    filled: true
    fillColor: theme.inputFill
    hintText: '••••••'
    hintStyle: TextStyle(color: theme.inputHintText)
    border: OutlineInputBorder(borderRadius: 12, borderSide: color: theme.inputBorder)
    enabledBorder: OutlineInputBorder(borderRadius: 12, borderSide: color: theme.inputBorder)
    focusedBorder: OutlineInputBorder(borderRadius: 12, borderSide: color: theme.inputFocusedBorder)
    suffixIcon: IconButton
      icon: _obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined
      color: theme.visibilityIconColor
      onPressed: setState(() => _obscureText = !_obscureText)
SizedBox(height: 24)
```

##### D. System Mode Selector
```
Label: _buildLabel('SYSTEM MODE', theme)
SizedBox(height: 8)
Container:
  padding: EdgeInsets.all(4)
  decoration:
    color: theme.inputFill
    borderRadius: 12
  child: Row of 3x _buildModeButton:
    1. ('SPOT',      Icons.settings_suggest, SystemMode.spot)
    2. ('CRUMBLING', Icons.school,           SystemMode.crumbling)
    3. ('MAINT',     Icons.build,            SystemMode.maintenance)
SizedBox(height: 32)
```

##### E. Initialize Button
```
SizedBox(height: 56):
  ElevatedButton:
    style:
      backgroundColor: theme.primaryButtonBackground
      foregroundColor: theme.primaryButtonText
      shape: RoundedRectangleBorder(borderRadius: 12)
      elevation: 0
      shadowColor: theme.primaryButtonShadow
    child: Row(mainAxisAlignment: center):
      Text 'INITIALIZE SYSTEM' (fontSize: 16, fontWeight: bold)
      SizedBox(width: 8)
      Icon(Icons.arrow_forward)
```

##### F. USB Status Row
```
SizedBox(height: 16)
Row(mainAxisAlignment: spaceBetween):
  child: _buildUsbStatus(ref, theme)
```

---

## Helper Widgets

### `_buildLabel(String text, AppThemeData theme)`
Standardized form label used across the login form.
```
Text(text):
  color: theme.labelColor
  fontSize: 12
  fontWeight: bold
  letterSpacing: 0.5
```

### `_buildModeButton(String label, IconData icon, SystemMode mode, AppThemeData theme)`
Each mode button is an `Expanded` → `GestureDetector` → `Container`:
```
Container:
  padding: EdgeInsets.symmetric(vertical: 12)
  decoration:
    color: isSelected ? theme.modeButtonSelectedBackground : theme.modeButtonBackground
    borderRadius: 8
  child: Row(mainAxisAlignment: center):
    Icon(icon, size: 16)
      color: isSelected ? theme.modeButtonSelectedText : theme.modeButtonText
    SizedBox(width: 8)
    Text(label, fontWeight: bold)
      color: isSelected ? theme.modeButtonSelectedText : theme.modeButtonText
  onTap: setState(() => _selectedMode = mode)
```

### `_buildUsbStatus(WidgetRef ref, AppThemeData theme)`
Live connectivity indicator watching `comServiceProvider`:
```
Logic:
  1. Read `usbState.lastDataReceived`.
  2. If non-null AND time difference < 2 seconds → hasDataStream = true.
  3. isActive = usbState.isConnected && hasDataStream.

Colors (semantic, fixed — not theme-dependent):
  Active:   Colors.green
  Inactive: Colors.red

Layout: Row
  - Icon(Icons.usb, color: indicatorColor, size: 14)
  - SizedBox(width: 4)
  - Text('Connection to RS232 : ', color: theme.usbLabelColor, fontSize: 12)
  - Text(isActive ? 'Active' : 'Inactive',
      color: indicatorColor, fontSize: 12, fontWeight: bold)
  - SizedBox(width: 6)
  - Container(8x8 circle):
      color: indicatorColor
      boxShadow: if active → green glow (alpha: 0.6, blurRadius: 4, spreadRadius: 1)
```

---

## Authentication Flow (onPressed Logic)
The `INITIALIZE SYSTEM` button performs sequential validation:

```
1. if (_selectedPerson == null)
   → NotificationService.showError('Select an Operator') → return

2. if (_passwordController.text.isEmpty)
   → NotificationService.showError('Enter Password') → return

3. if (_passwordController.text != _selectedPerson!.password)
   → NotificationService.showError('Invalid Password') → return

4. Success:
   → NotificationService.showSuccess('Welcome ${_selectedPerson!.firstName}')
   → ref.read(authProvider.notifier).login(_selectedPerson!, _selectedMode)
   → This mutates AuthState (sets currentUser + mode)
   → LandingPage reactively detects authenticated state → routes to HomePage
```

---

## Theme Token Reference (Login-Specific)

| Token                         | Dark Value          | Light Value         |
|-------------------------------|---------------------|---------------------|
| `cardBackground`              | `0xFF1A2235`        | `0xFFFFFFFF`        |
| `cardBorder`                  | `0xFF2A3750`        | `0xFF00BCD4`        |
| `overlayOpacity`              | `0.40`              | `0.15`              |
| `titleColor`                  | `0xFFFFFFFF`        | `0xFF1A1A2E`        |
| `subtitleColor`               | `0xFF8A94A6`        | `0xFF7A8290`        |
| `labelColor`                  | `0xFF00BCD4`        | `0xFF00BCD4`        |
| `inputFill`                   | `0xFF222B40`        | `0xFFF5F7FA`        |
| `inputBorder`                 | `0xFF2A3040`        | `0xFFD0D4DA`        |
| `inputFocusedBorder`          | `0xFF00BCD4`        | `0xFF00BCD4`        |
| `inputHintText`               | `0xFF8A94A6`        | `0xFF7A8290`        |
| `inputTextColor`              | `0xFFFFFFFF`        | `0xFF1A1A2E`        |
| `visibilityIconColor`         | `0xFF8A94A6`        | `0xFF7A8290`        |
| `dropdownBackground`          | `0xFF1A2235`        | `0xFFFFFFFF`        |
| `dropdownIcon`                | `0xFF00BCD4`        | `0xFF00BCD4`        |
| `dropdownItemText`            | `0xFFFFFFFF`        | `0xFF1A1A2E`        |
| `dropdownHintText`            | `0xFF8A94A6`        | `0xFF7A8290`        |
| `modeButtonBackground`        | `transparent`       | `transparent`       |
| `modeButtonSelectedBackground`| `0xFF00BCD4`        | `0xFF00BCD4`        |
| `modeButtonText`              | `0xFF8A94A6`        | `0xFF7A8290`        |
| `modeButtonSelectedText`      | `0xFF0D1118`        | `0xFFFFFFFF`        |
| `primaryButtonBackground`     | `0xFF00BCD4`        | `0xFF00BCD4`        |
| `primaryButtonText`           | `0xFF0D1118`        | `0xFFFFFFFF`        |
| `primaryButtonShadow`         | `0x8000BCD4`        | `0x6000BCD4`        |
| `usbLabelColor`               | `0xFF8A94A6`        | `0xFF7A8290`        |
| `logoBadgeBackground`         | `0x99000000`        | `0xCCFFFFFF`        |
| `logoBadgeBorder`             | `0xFF00BCD4`        | `0xFF00BCD4`        |

## Required Assets
- `images/login_bg.jpeg` — Full-bleed cinematic background photograph.
- `images/logoToho.png` — Company logo icon (32px height in logo badge).
