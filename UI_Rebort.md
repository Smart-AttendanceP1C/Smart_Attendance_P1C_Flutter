#  VeriShift / AttendSync Platform

### Cryptographically Verified Smart Attendance System

VeriShift / AttendSync is an enterprise-grade mobile attendance platform designed for higher education institutions. The system combines institutional Single Sign-On (SSO), Bluetooth Low Energy (BLE) technologies, dynamic QR codes, and geofencing to provide a secure, transparent, and reliable attendance experience.

---

##  Table of Contents

* [Overview](#-overview)
* [Key Features](#-key-features)
* [System Workflow](#-system-workflow)
* [Student Application](#-student-application)
* [Instructor Portal](#-instructor-portal)
* [Telemetry and System Support](#-telemetry-and-system-support)
* [UI/UX Design System](#-uiux-design-system)
* [Security Architecture](#-security-architecture)
* [Project Structure](#-project-structure)
* [Future Enhancements](#-future-enhancements)

---

## Overview

VeriShift / AttendSync aims to modernize academic attendance management through multi-layer identity and location verification.

The platform is designed to support:

* Secure student authentication.
* Real-time attendance verification.
* Dynamic QR-based classroom check-in.
* BLE beacon and geofence validation.
* Transparent attendance records.
* Attendance correction and dispute management.
* Instructor session management.
* Hardware and network diagnostics.

> **Project Status:** UI/UX design and system architecture specification.

---

## Key Features

| Feature                  | Description                                                                    |
| ------------------------ | ------------------------------------------------------------------------------ |
|  Institutional SSO     | Authentication through Microsoft Entra ID.                                     |
|  Geofencing            | Verifies whether the student is within the permitted campus or classroom area. |
|  BLE Verification      | Uses Bluetooth Low Energy beacon signals for proximity validation.             |
|  Dynamic QR Codes      | Time-limited QR tokens for classroom attendance.                               |
|  Time Synchronization  | Supports synchronized timestamps for attendance events.                        |
|  Academic Ledger       | Chronological attendance history and verification records.                     |
|  Dispute Management    | Submit and track attendance correction requests.                               |
|  Faculty Portal     | Instructor tools for sessions, rosters, and attendance monitoring.             |
|  Hardware Diagnostics | Monitoring of BLE nodes, network links, and location telemetry.                |
|  Helpdesk              | In-app technical support and documentation.                                    |

---

## 🔄 System Workflow

The platform is organized into six primary phases.

### Phase 1: Onboarding and Authentication

#### Student Registration

The registration screen allows students to create their accounts using:

* Full Name
* Student ID
* Institutional Email
* Phone Number
* Date of Birth
* Institution
* Grade or Cohort
* Password Confirmation

**Authentication:** Microsoft Entra ID institutional Single Sign-On (SSO).

#### Institutional Login and Geofence Verification

Students authenticate using their institutional credentials.

**UI Components:**

* Campus Email or ID input.
* Institutional tenant badge.
* Faculty and program selectors.
* Geofence verification indicator.
* Alternative authentication options, where supported.

---

### Phase 2: Global Navigation

#### Interactive Navigation Drawer

The navigation drawer provides access to the platform's main modules.

**Student Identity Header:**

* Student name.
* Department.
* Student ID.
* Attendance rate.
* Attended classes counter.
* Active dispute counter.

**Navigation Modules:**

| Category               | Modules                                      |
| ---------------------- | -------------------------------------------- |
| Core Attendance        | Student Home, QR Scanner, Dynamic Pass/Badge |
| Records and Compliance | Attendance History, Correction Requests      |
| Account and Telemetry  | Hardware Diagnostics, IT Support             |
| Faculty Access         | Instructor Portal Switcher                   |

---

### Phase 3: Student Attendance Workflows

#### Main Student Dashboard

The dashboard acts as the central hub for attendance activities and academic statistics.

**UI Components:**

* Active lecture session.
* Course code and course name.
* Lecture room.
* Instructor information.
* Remaining session time.
* Campus geofence status.
* BLE beacon connection status.
* Attendance analytics.
* Absence buffer information.
* Attended, absent, and late statistics.

**Example Session:**

```text
Course: CS-402 — Deep Learning
Room: B-304
Instructor: Course Instructor
Session Status: Active
```

#### Dynamic QR Scanner

Students can scan a time-limited QR code displayed in the classroom.

**UI Components:**

* Camera preview.
* Dynamic QR scanning frame.
* BLE signal strength indicator.
* Geofence verification badge.
* PIN fallback input.
* Attendance validation status.
* Testing and simulation controls.

#### Attendance Attested and Synced

After successful attendance verification, the student receives a confirmation screen.

**UI Components:**

* Prominent "Synced" status.
* Attendance timestamp.
* Course code.
* Lecture hall.
* Verification summary.
* Return Home action.
* View Attendance Logs action.

---

### Phase 4: Academic Ledger and Compliance

#### Attendance History

The academic ledger provides a chronological record of attendance events.

**Filtering Options:**

* Date range.
* Course code.
* Verification status.
* Attendance event type.

**Supported Status Examples:**

* Verified.
* Excused.
* Flagged.
* Late.

**Historical Event Information:**

* Course code.
* Attendance timestamp.
* Arrival status.
* Terminal ID.
* BLE beacon node IDs.
* Verification metadata.
* Audit hash reference.

> Audit hashes may be used to reference the integrity record of an attendance event. The implementation must ensure that any displayed hash corresponds to a real, verifiable record.

#### Correction Request and Dispute Resolution

Students can submit requests to review attendance records.

**UI Components:**

* Ledger receipt details.
* Ticket ID.
* Course code.
* Scan timestamp.
* Reason for the request.
* Supporting evidence attachments.
* Dispute status tracker.
* PDF receipt export.
* Helpdesk contact links.

**Dispute Workflow:**

```text
Request Submitted
        ↓
Instructor Review
        ↓
Ledger Record Update
```

---

### Phase 5: Instructor and Faculty Portal

#### Lecturer Dashboard

The instructor dashboard provides tools for managing attendance sessions and reviewing student records.

**UI Components:**

* Active lecture sessions.
* Student attendance headcount.
* Average attendance statistics.
* Course roster management.
* Dynamic QR broadcast controls.
* Manual attendance correction tools.
* Excuse and dispute review queue.

#### Session QR Code Generator

The classroom portal allows instructors to generate dynamic QR codes for attendance sessions.

**UI Components:**

* Active course header.
* Session status indicator.
* Generate QR Code button.
* QR code display area.
* Token expiration countdown.
* Session information.

**Example Session:**

```text
Course: CS-401 — Advanced Algorithms
Session Status: Active
QR Token: Time-Limited
```

> QR expiration intervals and token rotation periods are configurable system parameters and should be implemented according to the final security design.

---

### Phase 6: Telemetry Engine and System Support

#### Hardware Diagnostics

The telemetry dashboard provides visibility into device, network, and positioning information.

**UI Components:**

* BLE mesh node status.
* RSSI signal readings.
* Beacon connectivity.
* Geofence information.
* Location and floor metadata.
* Indoor positioning status.
* Network connectivity metrics.
* Clock synchronization status.
* Device integrity indicators.

#### Helpdesk and Support

The support screen provides access to institutional assistance and system documentation.

**UI Components:**

* Frequently Asked Questions (FAQ).
* Expandable help categories.
* Email support.
* Telephone support.
* Institutional ID display.
* Feedback submission form.
* Application version metadata.

#### Session Security and Logout Confirmation

The logout confirmation screen helps prevent accidental session termination.

**UI Components:**

* Active beacon status summary.
* Session security information.
* Pass or badge unbinding notice.
* Biometric quick-login setting, if supported.
* Confirm Logout action.
* Stay Logged In action.

---

##  Student Application Screens

The following screens represent the main student-side UI/UX flow:

1. Student Registration.
2. Institutional SSO Login.
3. Geofence Verification.
4. Express Student Check-In.
5. Student Dashboard.
6. Dynamic QR Scanner.
7. Attendance Synced Confirmation.
8. Attendance History.
9. Correction Request.
10. Dispute Tracking.
11. Hardware Diagnostics.
12. Helpdesk and Support.
13. Logout Confirmation.

---

##  Instructor Portal Screens

The instructor-side experience includes:

1. Faculty Login.
2. Lecturer Dashboard.
3. Active Session Management.
4. Course Roster Management.
5. Dynamic QR Code Generator.
6. Attendance Monitoring.
7. Manual Attendance Review.
8. Excuse and Dispute Management.
9. Session History.

---

##  Telemetry and System Support

The platform's telemetry layer is designed to expose technical information required for monitoring and troubleshooting.

### BLE Mesh Nodes

Provides information about nearby BLE beacon nodes, including signal readings and connection status.

### Geofence and Spatial Data

Displays location-related metadata, such as:

* Campus or building identifier.
* Floor information.
* Geofence status.
* Positioning accuracy estimates.
* Indoor positioning state.

### Clock Synchronization

Supports consistent timestamps across attendance devices and services.

### Network and Hardware Integrity

Provides diagnostic information related to:

* Device integrity.
* Network connectivity.
* BLE availability.
* Hardware status.
* Application telemetry.

> Telemetry data should be collected, displayed, and stored according to institutional privacy and security requirements.

---

##  UI/UX Design System

### Color Palette

| Color         | Hex Code  | Usage                          |
| ------------- | --------- | ------------------------------ |
| Navy Blue     | `#1E3A8A` | Primary brand and navigation   |
| Soft Gray     | `#F8FAFC` | Background surfaces            |
| Success Green | `#10B981` | Verified and successful states |
| Warning Amber | `#F59E0B` | Warnings and pending states    |

### Design Principles

* Clear and consistent navigation.
* Responsive mobile-first layouts.
* Accessible color contrast.
* Real-time status feedback.
* Consistent spacing and typography.
* Clear error and success states.
* Confirmation dialogs for sensitive actions.
* Simple attendance workflows.
* Visual hierarchy for important information.

### UI Components

The design system may include:

* Navigation drawers.
* Cards.
* Progress indicators.
* Status badges.
* Countdown timers.
* QR scanning overlays.
* Signal strength meters.
* Filter controls.
* Modal dialogs.
* Progress trackers.
* Empty states.
* Error and success messages.

---

##  Security Architecture

The platform is designed around multiple layers of identity, time, and location verification.

### Proposed Verification Layers

```text
Institutional Identity
        ↓
Device and Session Validation
        ↓
BLE Proximity Verification
        ↓
Geofence Validation
        ↓
Dynamic QR Token Validation
        ↓
Timestamp and Event Integrity
        ↓
Attendance Record
```

### Security Considerations

* Microsoft Entra ID authentication.
* Secure token generation and validation.
* Time-limited QR codes.
* Replay protection.
* Server-side attendance verification.
* Secure storage of sensitive information.
* Role-based access control.
* Audit logging.
* Privacy-aware telemetry collection.
* Secure session termination.

> BLE proximity and geofence measurements are subject to environmental and device limitations. They should be combined with server-side validation and appropriate institutional policies rather than treated as perfect proof of physical presence.

---

##  Project Structure

The following structure is a proposed organization for the project and can be adapted to the final implementation.

```text
VeriShift-AttendSync/
│
├── README.md
│
├── mobile_app/
│   ├── lib/
│   │   ├── main.dart
│   │   ├── core/
│   │   ├── models/
│   │   ├── services/
│   │   ├── screens/
│   │   ├── widgets/
│   │   └── navigation/
│   │
│   ├── assets/
│   └── pubspec.yaml
│
├── backend/
│   ├── authentication/
│   ├── attendance/
│   ├── qr_tokens/
│   ├── geofencing/
│   ├── ble_verification/
│   ├── ledger/
│   └── support/
│
├── security/
│   ├── identity_verification/
│   ├── token_validation/
│   ├── audit_logging/
│   └── access_control/
│
├── data_analysis/
│   ├── attendance_reports/
│   ├── analytics/
│   └── dashboards/
│
├── testing/
│   ├── unit_tests/
│   ├── integration_tests/
│   ├── security_tests/
│   └── ui_tests/
│
└── docs/
    ├── ui_ux_specification.md
    ├── system_architecture.md
    └── api_documentation.md
```

---

##  Example Attendance Analytics

The dashboard can display attendance information through summary cards and visual indicators.

Example metrics:

```text
Attendance Rate: 94.2%
Attended Classes: 28 / 30
Late Flags: 2
Absences: 1
```

*The values above are illustrative UI examples and do not represent live attendance data.*

---

##  Future Enhancements

Potential future improvements include:

* Offline attendance event queuing.
* Enhanced indoor positioning.
* Advanced attendance analytics.
* Automated anomaly detection.
* Improved accessibility support.
* Multi-institution support.
* Administrative reporting dashboards.
* More comprehensive device integrity checks.
* Integration with existing university information systems.

---

##  Project Goals

VeriShift / AttendSync aims to deliver:

1. A reliable and user-friendly attendance experience.
2. Transparent academic attendance records.
3. Multi-layer verification of attendance events.
4. Efficient instructor attendance management.
5. Clear correction and dispute workflows.
6. A scalable architecture for higher education institutions.

---

##  Documentation

Additional project documentation can include:

* UI/UX Design Specifications.
* System Architecture Documentation.
* API Documentation.
* Database Schema.
* Security and Privacy Requirements.
* Testing and Quality Assurance Reports.

---

##  Project Information

**Project Name:** VeriShift / AttendSync

**Domain:** Smart Attendance and Academic Management

**Target Users:** Students, Instructors, Faculty Administrators, and IT Support Teams

**Platform:** Mobile Application and Faculty Web Portal

**Development Status:** UI/UX and Architecture Planning

---

##  License

This project is intended for academic and educational development. Licensing details can be added according to the final project requirements.
