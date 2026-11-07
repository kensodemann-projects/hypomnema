# Contributing

## Prerequisites

Install the [Flutter SDK](https://docs.flutter.dev/get-started/install). This app requires the Dart SDK constraint in `pubspec.yaml` (`^3.13.7`). `material_ui` requires Flutter `3.47.0` or newer.

Check the toolchain before starting:

```sh
flutter doctor
```

## Dependencies

From the repository root:

```sh
flutter pub get
```

## Run

List devices, then run on one of them:

```sh
flutter devices
flutter run -d <device>
```

Local debug runs on Android, macOS, and Chrome use the Firebase Auth and Firestore emulators. Start them from the repository root before `flutter run` or `flutter run -d chrome`:

```sh
firebase emulators:start --only auth,firestore
```

Phone and desktop are both required form factors. Run on a phone (a device or simulator) and on a desktop target before considering a UI change done.

Import UI widgets from `package:material_ui/material_ui.dart`.

## Format, analyze, and test

`analysis_options.yaml` includes `package:flutter_lints/flutter.yaml`. Before a change is ready:

```sh
dart format .
flutter analyze
flutter test
```

## Workflow

Follow the loop in [kensodemann/my-skills](https://github.com/kensodemann/my-skills). Invoke a skill with `/skill-name`, or describe the work and let the agent match the skill.

1. **capture-intent** writes one root `INTENT.md`. That file is a working draft and is not committed. This step does not create the GitHub issue.
2. **create-feature**, **create-task**, or **create-bug** files the issue from that accepted intent, or from a prompt. This repository needs `.github/ISSUE_TEMPLATE/bug.md`, `feature.md`, and `task.md`. If any of the three is missing, the issue skill names the missing files and waits.
   1. A feature must be broken into leaf child tasks with **create-tasks** (`/create-tasks #N`).
   2. A feature is never planned directly.
   3. A task is one unit of work. **create-task** creates it stand-alone unless the human names a parent feature, and a task is never a parent. A stand-alone task may reference a related feature or another task, and that reference is not a parent.
   4. A bug is a stand-alone defect and is never split. It may reference a related feature or task, and it is never a child of that issue. The tree is only a feature and its child tasks.
3. **plan-implementation** writes one root `PLAN.md` for a task or a bug. Each step lists the test files for that change. A feature is refused until **create-tasks** has divided it. Do this on a feature branch, not on `main`.
4. **implement-next-step** carries out the next incomplete step and asks the human to validate it. It marks the step complete only after the human says it is complete. The human commits. When the human says `tests only` or `tests-only`, that step's tests are written and production code stays unchanged. Further changes stay on that step until the human says it is complete.
5. The human opens the pull request.
6. **review-pull-request** writes `REVIEW.md` and does not post on the pull request.
7. The human addresses that feedback with ordinary prompts. No skill owns that turn.

**create-tests** and **update-deps** stay outside that loop. **create-tests** in that repository covers Vitest tests for behavior already in the codebase. **update-deps** takes patch and minor npm and pnpm updates. In this repository, tests are `flutter test` and dependencies are Dart packages.
