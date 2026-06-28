# Requirements Clarification Questions

Please answer the following questions to help clarify your project requirements.

## Question 1

What type of application or system would you like to build?

A) Web application (frontend + backend)

B) Backend API / microservice

C) CLI tool or command-line utility

D) Library or package (reusable code module)

E) Other (please describe after [Answer]: tag below)

[Answer]: E ― Game

## Question 2

What is the primary programming language you'd like to use?

A) Python

B) TypeScript / JavaScript

C) Java

D) Go

E) Other (please describe after [Answer]: tag below)

[Answer]: E ― GDScript

## Question 3

What is the main purpose or goal of this project?

A) Internal tool or automation

B) Customer-facing product or service

C) Learning / educational project

D) Open-source contribution

E) Other (please describe after [Answer]: tag below)

[Answer]: A

## Question 4

How would you describe the expected complexity of this project?

A) Simple (single feature, minimal logic)

B) Moderate (multiple features, some integration)

C) Complex (many components, complex business logic, external integrations)

D) Other (please describe after [Answer]: tag below)

[Answer]: C

## Question: Resiliency Extensions

Should the resiliency baseline be applied to this project?

**What this extension is.** Enabling it applies a set of **directional,
design-time best practices** for building resilient systems, derived from the
**AWS Well-Architected Framework (Reliability Pillar)** and resilience-review
guidance. It steers requirements, design, and code toward fault tolerance, high
availability, observability, and recoverability — covering 15 practice areas
across business goals, change management, observability, high availability,
disaster recovery, and continuous improvement.

**What this extension is NOT.** Enabling it does **not** make your workload
production-ready, nor does it certify or guarantee any availability, RTO, or RPO
target. It is a **starting point** that scaffolds good resiliency decisions
early — it is not a substitute for a formal **AWS Well-Architected Review** of
the built system.

Treat the output as a well-grounded **first draft of your resiliency posture**
to build on and validate — not a finished, production-certified result.

A) Yes — apply the resiliency baseline as directional best practices and
design-time guidance (recommended for business-critical workloads, as an
informed starting point that you can validate and harden before go-live)

B) No — skip the resiliency baseline (suitable for PoCs, prototypes, and
experimental projects where rapid iteration matters more than reliability)

X) Other (please describe after [Answer]: tag below)

[Answer]: B

## Question: Security Extensions

Should security extension rules be enforced for this project?

A) Yes — enforce all SECURITY rules as blocking constraints (recommended for
production-grade applications)

B) No — skip all SECURITY rules (suitable for PoCs, prototypes, and experimental
projects)

X) Other (please describe after [Answer]: tag below)

[Answer]: B

## Question: Property-Based Testing Extension

Should property-based testing (PBT) rules be enforced for this project?

A) Yes — enforce all PBT rules as blocking constraints (recommended for projects
with business logic, data transformations, serialization, or stateful
components)

B) Partial — enforce PBT rules only for pure functions and serialization
round-trips (suitable for projects with limited algorithmic complexity)

C) No — skip all PBT rules (suitable for simple CRUD applications, UI-only
projects, or thin integration layers with no significant business logic)

X) Other (please describe after [Answer]: tag below)

[Answer]: C
