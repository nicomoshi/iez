# Stuari — Accessibility Label Gaps

Audit of `~/Developer/sestuary/lib/` — widgets that lack explicit
`Semantics(label:)` wrappers where adding one would make iEZ tests
significantly more reliable. **These gaps are NOT fixed by this PR**;
this file is a to-do list for a future "label harvest" pass.

Labels are only listed as gaps when:

- The widget participates in a core user flow (tappable, critical
  verification), AND
- The auto-derived AX label is ambiguous, dynamic, or missing

## Critical gaps (blocks reliable automation)

| Widget file | Issue | Suggested label |
|---|---|---|
| `habit_group/widgets/create_habit_*_page.dart` | Every step uses the same `Continue` label → tests can't distinguish which step Continue belongs to | Wrap with `Semantics(label: 'Continue: <step name>')` |
| `home/widgets/habit_carousel.dart` + card widgets | Habit cards lack per-card semantic labels beyond the habit title text; taps by label collide when two habits share a name | Add `Semantics(label: 'Habit card: <name>')` around each card |
| `camera/widgets/camera_controls.dart` flash / torch toggles | Only the shutter and stop buttons have `Semantics`. Flash, torch, gallery, and close buttons are bare `IconButton`s whose tooltip (if any) may not propagate on iOS | Add explicit `tooltip:` or `Semantics(label:)` for `Flash`, `Torch`, `Flip camera`, `Close camera` |
| `chat/widgets/chat_input_bar.dart` | The `TextField` itself doesn't have a labelText (only a hint) → iEZ matches against the hint which changes when filled | Add `labelText: 'Message input'` or wrap in `Semantics(label: 'Chat message input')` |
| `comments/widgets/comment_input_bar.dart` | Same as chat — input has no stable label | Add explicit input label |
| `feed/widgets/like_button.dart` | `Semantics(button: true)` without a label → iEZ must guess based on parent Row text | Add `label: 'Like'` / `label: 'Unlike'` depending on `isLiked` |
| `feed/widgets/feed_post_card.dart` (root tap target) | Tapping the post card to open the detail has no explicit label; tests rely on the comments subtext which may not always be present | Wrap card body with `Semantics(button: true, label: 'Open post by <author>')` |
| `chat/widgets/chat_message_bubble.dart` (text bubbles) | Image bubbles have `Semantics(image: true)` but text bubbles rely on the raw text node → long-press target is the Text widget, which iEZ can find but substring matching is fragile | Add `Semantics(button: true, label: 'Message from <sender>: <preview>')` |
| `notifications/` list items | Notification rows don't expose their action target as a stable label; iEZ has to regex on "liked", "commented", etc. | Add per-notification semantic label including actor + verb + object |
| `discover/widgets/discover_post_card.dart` | Public feed cards have no distinct label vs private feed cards | Prefix labels with `Discover:` |
| `confirmation/widgets/confirmation_action_button.dart` | Approve/Reject buttons on the overlay appear twice (one per pending check-in); iEZ can't target a specific one | Append subject: `Approve check-in from <name>` |

## Medium-priority gaps (workarounds exist)

| Widget file | Issue | Suggested label |
|---|---|---|
| `journal/widgets/month_nav_button.dart` | Has a `Semantics` per `JournalSemantics.previousMonth` but tests show ambiguous labels on some months | Standardize to `Previous month` / `Next month` literal |
| `home/widgets/bottom_sheet_tabs.dart` | Feed/Journal/Stats tab labels are the single-word text nodes — fine in isolation but collide with the Feed tab-bar label | Prefix with context: `Home sheet: Feed` |
| `profile/view/profile_settings_page.dart` | Form fields don't have `labelText` — just `hintText` | Add `labelText: 'Display Name'`, `labelText: 'Bio'`, etc. |
| `home/widgets/create_habit_card.dart` | Label already good (`'Create Habit. Tap to start a new journey.'`) but 3 other habit-card variants also claim label `'Create new habit'` — label collision | Differentiate by variant: `Create Habit (dark)`, `Create Habit (simple)`, etc. |
| `rewards/widgets/reward_button.dart` | Has `label: 'Send reward'` — good. But the reward tier buttons inside the sheet use their display name as text only | Add `Semantics(label: 'Reward tier: <name>')` |

## Nice-to-have

- Every `ElevatedButton(child: Text('X'))` flattens to label "X". Where
  `X` is generic (`Save`, `Continue`, `Done`, `Next`), wrap with
  `Semantics(label: '<scope>: <X>')` to disambiguate in tests.
- Consider publishing a small `JournalSemantics` / `HabitSemantics` /
  `FeedSemantics` constants file under `design_system/` mirroring
  `stuari_semantics.dart`, so tests can depend on named constants
  instead of hard-coded strings.

## How to apply

Use the existing `StuariSemantics` wrapper
(`lib/design_system/stuari_semantics.dart`):

```dart
StuariSemantics(
  label: 'Approve check-in from Stu',
  button: true,
  onTap: () => cubit.approve(),
  child: ConfirmationActionButton(...),
)
```

After labels land, `iez ui tree --compact` should show a stable, human
readable label for every interactive element along the critical paths.
