# Artifact Mappings Reference

This reference maps each of the 20 NIST 800-53 artifact sections to specific file
patterns, code patterns, and search strategies for discovering evidence in a repository.

## Table of Contents
1. [System Design Document](#1-system-design-document)
2. [System Inventory](#2-system-inventory)
3. [Configuration Management Plan](#3-configuration-management-plan)
4. [Access Control & Account Management](#4-access-control--account-management)
5. [Authentication & Session Configuration](#5-authentication--session-configuration)
6. [Audit Logging & Monitoring](#6-audit-logging--monitoring)
7. [Vulnerability & Patch Management](#7-vulnerability--patch-management)
8. [Incident Response Plan](#8-incident-response-plan)
9. [Contingency Plan](#9-contingency-plan)
10. [Security Policies & Procedures](#10-security-policies--procedures)
11. [Personnel Security Records](#11-personnel-security-records)
12. [Security Awareness & Training](#12-security-awareness--training)
13. [System Maintenance Records](#13-system-maintenance-records)
14. [Physical & Environmental Protection](#14-physical--environmental-protection)
15. [Media Protection Records](#15-media-protection-records)
16. [Network & Communications Security](#16-network--communications-security)
17. [SDLC & Secure Development](#17-sdlc--secure-development)
18. [Supply Chain Risk Management](#18-supply-chain-risk-management)
19. [Interconnection & External Services](#19-interconnection--external-services)
20. [Risk Assessment & Categorization](#20-risk-assessment--categorization)

---

## 1. System Design Document

### File patterns
```
docs/**/architect*.md, docs/**/design*.md, docs/**/sdd*.md
README.md, REPO-README.md
docs/**/overview*.md, docs/**/system*.md
**/diagrams/**, **/images/architecture*
```

### Code patterns for generation
```
# Component inventory
Dockerfile*, docker-compose*.yml, **/Deployment.yaml, **/deployment*.yaml
**/BuildConfig.yaml, **/Service.yaml, **/Ingress.yaml

# Data flows
**/routes.php, **/Routes.php, **/urls.py, **/routes.*, **/router.*
**/controllers/**, **/Controllers/**, **/handlers/**
**/api/**, **/endpoints/**

# Auth design
**/auth*.*, **/Auth*.*, **/middleware/auth*
**/Filters/Auth*, **/guards/**, **/policies/**
config/saml/**, **/oauth/**, **/oidc/**

# Crypto
**/encrypt*.*, **/crypto*.*, **/tls*.*, **/ssl*.*
**/cert/**, **/certs/**, **/certificates/**
```

### Sub-items to check
- [ ] System name, purpose, high-level description
- [ ] System boundary definition
- [ ] Architecture diagrams (network, data flow, deployment)
- [ ] All system components described
- [ ] Data flows between components and external systems
- [ ] Ports, protocols, services with justification
- [ ] Trust boundaries and security zones
- [ ] Separation of user/admin functionality
- [ ] Data/tenant separation
- [ ] Memory protection and process isolation
- [ ] Authentication and authorization design
- [ ] Cryptographic design
- [ ] Collaborative computing devices, mobile code, shared resources

---

## 2. System Inventory

### File patterns
```
# PHP
composer.json, composer.lock
# Node (TS + JS)
package.json, package-lock.json, yarn.lock, pnpm-lock.yaml, tsconfig.json
# Python
requirements.txt, Pipfile, Pipfile.lock, poetry.lock, pyproject.toml, setup.py, setup.cfg
# Rust
Cargo.toml, Cargo.lock
# Go
go.mod, go.sum
# Ruby
Gemfile, Gemfile.lock, *.gemspec, Rakefile
# JVM (Java / Kotlin)
**/pom.xml, **/build.gradle, **/build.gradle.kts, gradle/libs.versions.toml
# C# / .NET
**/*.csproj, **/*.sln, **/Directory.Build.props, **/Directory.Packages.props, **/appsettings*.json, **/packages.config
# Swift / Objective-C (SPM + Xcode)
Package.swift, Package.resolved, Podfile, Podfile.lock, **/*.xcodeproj/project.pbxproj
# C / C++
**/CMakeLists.txt, **/Makefile, configure.ac, configure.in, meson.build, vcpkg.json, conanfile.txt
# R
DESCRIPTION, renv.lock, packrat/, install.R
# SAS (no universal manifest — treat *.sas presence as the marker)
**/*.sas
# Perl
Makefile.PL, cpanfile, cpanfile.snapshot, MANIFEST, META.json
# SQL (standalone, no host-language marker)
.sqlfluff, **/schema.sql, **/migrations/**/*.sql
```

### Code patterns for generation
```
# Infrastructure components
Dockerfile*, docker-compose*.yml
**/Deployment.yaml, **/StatefulSet.yaml
**/terraform/*.tf, **/cloudformation/*.yaml
openshift/**/*.yaml

# Database
**/migrations/**, **/schema*.sql, **/database*.*
**/models/**, **/entities/**

# Third-party integrations
.env.sample (look for service URLs and API endpoints)
```

### Sub-items to check
- [ ] Hardware components (servers, network, storage, endpoints, mobile)
- [ ] Software (OS, middleware, apps, databases, libraries, agents)
- [ ] Firmware components
- [ ] Version/release numbers for every component
- [ ] Responsible owner/role per component
- [ ] Physical or logical location
- [ ] Installation/last-updated dates
- [ ] Vendor support status (EOL flags)
- [ ] Data types per component
- [ ] Components awaiting/returning from service

---

## 3. Configuration Management Plan

### File patterns
```
.github/**, .gitlab-ci.yml, Jenkinsfile, azure-pipelines.yml
.github/PULL_REQUEST_TEMPLATE*, .github/CODEOWNERS
**/CONTRIBUTING.md, **/DEVELOPMENT.md
docs/**/config*.md, docs/**/change*.md
```

### Code patterns for generation
```
# Baseline configs
Dockerfile (base image = baseline)
config/**/*, **/Config/**/*
.editorconfig, .eslintrc*, .prettierrc*, tslint.json
**/phpcs.xml, **/phpstan.neon, **/psalm.xml

# Change detection
.gitleaks.toml, .gitattributes
**/renovate.json, **/dependabot.yml

# Hardening references (in comments or docs)
Grep: "STIG", "CIS", "USGCB", "hardening", "benchmark"
```

### Sub-items to check
- [ ] CCB or governance body identified
- [ ] Change proposal/review/approval/test/implement process
- [ ] Security impact analysis for changes
- [ ] Pre-production testing evidence
- [ ] Baseline configuration per component type
- [ ] Hardening standards referenced (STIG, CIS, etc.)
- [ ] Baseline review frequency
- [ ] Older baseline version retention
- [ ] Unauthorized change detection (FIM, SIEM)
- [ ] Software allowlist/denylist
- [ ] User software installation restrictions
- [ ] Mobile device configuration policies
- [ ] Change ticket history

---

## 4. Access Control & Account Management

### File patterns
```
docs/**/access*.md, docs/**/account*.md
**/RBAC*.*, **/roles*.*, **/permissions*.*
```

### Code patterns for generation
```
# Role definitions
**/Filters/Role*, **/middleware/role*
**/guards/**, **/policies/**, **/permissions/**
**/config/auth*.*, **/config/roles*.*
Grep: "role", "permission", "privilege", "admin", "superuser"

# Account management
**/controllers/account/**, **/Controllers/Auth*
**/models/user*.*, **/models/User*.*
**/migrations/*user*, **/migrations/*account*, **/migrations/*role*

# Separation of duties
Grep: "separation.*duties", "dual.*control", "segregat"
```

### Sub-items to check
- [ ] Complete account roster
- [ ] Access request tickets with approvals
- [ ] Periodic account reviews
- [ ] Separation of duties matrix
- [ ] Privileged account justification/approval
- [ ] Separate non-privileged accounts for admin users
- [ ] Shared/functional account inventory with justification
- [ ] Onboarding records
- [ ] Offboarding records
- [ ] Transfer/reassignment records
- [ ] Remote access authorization
- [ ] Mobile/wireless access authorization
- [ ] External system access authorization

---

## 5. Authentication & Session Configuration

### File patterns
```
config/**/auth*.*, config/**/session*.*
**/Config/App.*, **/config/config.*
config/saml/**, **/oauth*.*, **/oidc*.*
```

### Code patterns for generation
```
# Password policy
Grep: "password.*length", "password.*complex", "password.*history"
Grep: "lockout", "max.*attempt", "failed.*login"

# Session config
Grep: "session.*timeout", "session.*expir", "session.*idle"
Grep: "concurrent.*session", "session.*limit"

# MFA
Grep: "mfa", "multi.*factor", "two.*factor", "2fa", "totp", "yubikey"

# Banner
Grep: "banner", "warning.*message", "system.*use.*notification"
**/views/auth/**, **/templates/login*

# PIV/CAC
Grep: "piv", "cac", "smart.*card", "x509.*client"
```

### Sub-items to check
- [ ] Password length, complexity, history, age settings
- [ ] Account lockout threshold, duration, observation window
- [ ] Session lock timeout
- [ ] Concurrent session limits
- [ ] Network session termination
- [ ] MFA for privileged and non-privileged accounts
- [ ] Replay-resistant auth mechanisms
- [ ] Temporary password first-login change
- [ ] Password blocklist checking
- [ ] System use notification banner
- [ ] Default credentials changed
- [ ] PIV/CAC or federation config
- [ ] Contractor/foreign national account identifiers
- [ ] Session re-authentication and expiration
- [ ] Authentication feedback obscured
- [ ] Identity proofing process

---

## 6. Audit Logging & Monitoring

### File patterns
```
**/logging*.*, **/log_config*.*, **/log4j*.*, **/logback*.*
**/syslog*.*, **/rsyslog*.*, **/fluentd*.*, **/filebeat*.*
**/datadog*.*, **/newrelic*.*, **/splunk*.*
docs/**/audit*.md, docs/**/logging*.md, docs/**/monitoring*.md
```

### Code patterns for generation
```
# What's logged
Grep: "log\.(info|warn|error|debug|critical)", "logger\.", "Log::"
Grep: "audit.*log", "security.*log", "access.*log"
Grep: "log_message", "write_log", "LoggerInterface"

# Monitoring
Grep: "alert", "notify", "siem", "splunk", "datadog", "cloudwatch"
Grep: "ntp", "time.*source", "chronyd", "ntpd"

# Log protection
Grep: "log.*permission", "log.*access.*control", "log.*encrypt"
```

### Sub-items to check
- [ ] Audit policy: which events are logged
- [ ] Rationale for selected auditable events
- [ ] Sample log exports with required content (who, what, when, where, outcome)
- [ ] Audit storage capacity and retention
- [ ] NTP configuration (authoritative time source)
- [ ] Audit log protection (access controls)
- [ ] Log access restricted to authorized reviewers
- [ ] Alerting for audit failures/capacity thresholds
- [ ] SIEM/log aggregation integration
- [ ] Log correlation across repositories
- [ ] Log review/analysis process

---

## 7. Vulnerability & Patch Management

### File patterns
```
.github/workflows/*audit*, .github/workflows/*scan*
.github/workflows/*security*, .github/workflows/*snyk*
.github/workflows/*dependabot*, .github/dependabot.yml
**/renovate.json, **/renovate.json5
docs/**/vuln*.md, docs/**/patch*.md
.gitleaks.toml, .snyk, .trivyignore
```

### Code patterns for generation
```
# Scan configs
Grep: "vulnerability", "cve", "security.*scan"
Grep: "npm.*audit", "composer.*audit", "pip.*audit", "cargo.*audit"
Grep: "trivy", "grype", "snyk", "sonarqube", "veracode", "checkmarx"

# Malware/AV
Grep: "antivirus", "malware", "endpoint.*protection", "edr"
Grep: "clamav", "windows.*defender", "crowdstrike", "sentinel"

# FIM
Grep: "file.*integrity", "tripwire", "aide", "ossec", "wazuh"
```

### Sub-items to check
- [ ] Vulnerability scan reports (quarterly minimum)
- [ ] Patch remediation timeframes by severity
- [ ] Patch application records
- [ ] Pre-production patch testing
- [ ] Scan findings shared with stakeholders
- [ ] Risk acceptance records for deferred findings
- [ ] File integrity monitoring results
- [ ] Malware protection configuration
- [ ] Malware definition auto-update
- [ ] Scheduled full system scans
- [ ] On-access file scanning
- [ ] Malware detection response actions
- [ ] False positive handling records
- [ ] Public vulnerability disclosure process

---

## 8. Incident Response Plan

### File patterns
```
docs/**/incident*.md, docs/**/ir-*.md, docs/**/irp*.*
**/INCIDENT*.md, **/SECURITY.md
.github/ISSUE_TEMPLATE/incident*, .github/ISSUE_TEMPLATE/security*
```

### Code patterns for generation
```
Grep: "incident.*response", "escalation", "us-cert", "cisa"
Grep: "breach", "compromise", "forensic"
```

### Sub-items to check
- [ ] Written IRP with roles, escalation, reporting requirements
- [ ] IRP distributed to all personnel
- [ ] IR training materials
- [ ] Training completion records
- [ ] IR test plan and results
- [ ] IR test coordination with other plan owners
- [ ] Incident tracking log
- [ ] Sample incident tickets
- [ ] Customer/AO/oversight notification records
- [ ] Automated IR support tool

---

## 9. Contingency Plan

### File patterns
```
docs/**/contingency*.md, docs/**/disaster*.md, docs/**/dr-*.*
docs/**/backup*.md, docs/**/recovery*.md, docs/**/bcp*.*
```

### Code patterns for generation
```
# Backup evidence
Grep: "backup", "snapshot", "replicate", "failover"
Grep: "rto", "rpo", "recovery.*time", "recovery.*point"

# HA/DR configs
**/replicas*, **/replication*.*
Grep: "availability.*zone", "multi.*az", "cross.*region"
```

### Sub-items to check
- [ ] Written CP with RTO/RPO for all functions
- [ ] CP coordinated with IRP, DRP, other plans
- [ ] CP training materials and completion records
- [ ] CP test plan and results
- [ ] Critical asset inventory
- [ ] Alternate storage site documentation
- [ ] Alternate processing site documentation
- [ ] Telecom service agreements
- [ ] Backup schedule and evidence
- [ ] Backup testing/restoration records
- [ ] Backup encryption, access control, integrity verification
- [ ] Vendor SLAs for component failure
- [ ] Transaction recovery (if applicable)

---

## 10. Security Policies & Procedures

### File patterns
```
docs/**/polic*.md, docs/**/procedure*.md
docs/**/ac-*.md, docs/**/at-*.md, docs/**/au-*.md
docs/**/ca-*.md, docs/**/cm-*.md, docs/**/cp-*.md
docs/**/ia-*.md, docs/**/ir-*.md, docs/**/ma-*.md
docs/**/mp-*.md, docs/**/pe-*.md, docs/**/pl-*.md
docs/**/pm-*.md, docs/**/ps-*.md, docs/**/pt-*.md
docs/**/ra-*.md, docs/**/sa-*.md, docs/**/sc-*.md
docs/**/si-*.md, docs/**/sr-*.md
```

### Sub-items to check
For each of the 20 control families (AC, AT, AU, CA, CM, CP, IA, IR, MA, MP, PE, PL, PM, PS, PT, RA, SA, SC, SI, SR):
- [ ] Policy document exists
- [ ] Procedure document exists
- [ ] Purpose and scope stated
- [ ] Roles and responsibilities defined
- [ ] Policy statements tied to NIST requirements
- [ ] Review frequency and last review date
- [ ] Version history / revision log
- [ ] Update notification mechanism

---

## 11. Personnel Security Records

Typically OPERATIONAL — not in code repos.

### File patterns
```
docs/**/personnel*.md, docs/**/hr-*.md, docs/**/onboarding*.*
docs/**/offboarding*.*, docs/**/background*.*
**/rules-of-behavior*.*, **/acceptable-use*.*
```

### Sub-items to check
- [ ] Position risk designations
- [ ] Background check records
- [ ] Signed Rules of Behavior
- [ ] Signed access agreements and NDAs
- [ ] Vendor/contractor security agreements
- [ ] Personnel sanctions process communicated
- [ ] Job descriptions with security duties
- [ ] Screening/rescreening policy

---

## 12. Security Awareness & Training

Typically OPERATIONAL — not in code repos.

### File patterns
```
docs/**/training*.md, docs/**/awareness*.*
docs/**/security-training*.*
```

### Sub-items to check
- [ ] Security awareness training completion records
- [ ] Role-based security training records
- [ ] CP training records
- [ ] IR training records
- [ ] Training materials (general, insider threat, phishing, role-specific)
- [ ] Training before access/duties

---

## 13. System Maintenance Records

### File patterns
```
docs/**/maintenance*.md
**/CHANGELOG.md, **/CHANGES.md
```

### Code patterns for generation
```
# Git history as maintenance evidence
git log (recent maintenance activities)
```

### Sub-items to check
- [ ] Maintenance schedule and historical records
- [ ] Sample maintenance tickets
- [ ] Authorized maintenance organizations/personnel
- [ ] Offsite maintenance controls
- [ ] Diagnostic/maintenance tooling inspection records
- [ ] Nonlocal maintenance approval/monitoring
- [ ] Media sanitization/disposal records

---

## 14. Physical & Environmental Protection

Typically INHERITED for cloud-hosted systems.

### File patterns
```
docs/**/physical*.md, docs/**/pe-*.md
docs/**/facility*.md, docs/**/data-center*.*
```

### Sub-items to check
- [ ] Authorized physical access list
- [ ] Physical access logs
- [ ] Visitor access records
- [ ] Physical access device inventory
- [ ] Key/combination change records
- [ ] UPS/power/fire/water test records
- [ ] Environmental monitoring logs
- [ ] Equipment entry/exit records
- [ ] Alternate work site agreements

---

## 15. Media Protection Records

### File patterns
```
docs/**/media*.md, docs/**/mp-*.md
docs/**/sanitiz*.md, docs/**/disposal*.*
```

### Code patterns for generation
```
# USB/media controls
Grep: "usb", "removable.*media", "external.*storage"
```

### Sub-items to check
- [ ] Media type inventory with access restrictions
- [ ] Security classification labels
- [ ] Secure physical storage evidence
- [ ] Chain-of-custody records
- [ ] Media sanitization/disposal records
- [ ] Unauthorized media usage restrictions (USB controls)

---

## 16. Network & Communications Security

### File patterns
```
**/firewall*.*, **/iptables*.*, **/nftables*.*
**/NetworkPolicy*.yaml, **/security-group*.*
**/ingress*.yaml, **/Ingress*.yaml
**/nginx*.conf, **/httpd*.conf, **/apache*.*
**/tls*.*, **/ssl*.*, **/certificates/**
```

### Code patterns for generation
```
# Firewall rules
Grep: "firewall", "iptables", "security.*group", "network.*policy"
Grep: "allow", "deny", "ingress", "egress" (in K8s/cloud configs)

# TLS
Grep: "tls", "ssl", "https", "certificate", "cipher"
Grep: "FIPS", "fips.*140", "validated"

# DNS
Grep: "dns", "nameserver", "resolver", "dnssec"

# DoS protection
Grep: "ddos", "rate.*limit", "throttl", "waf"

# Input validation
Grep: "filter", "sanitiz", "validat", "escap", "htmlspecialchars"
Grep: "csrf", "xss", "injection"

# Error handling
Grep: "error.*handler", "exception.*handler", "display.*errors"
Grep: "stack.*trace", "debug.*mode", "CI_DEBUG"
```

### Sub-items to check
- [ ] Firewall rulesets and ACL configurations
- [ ] Public/internal network separation
- [ ] DMZ and boundary protection
- [ ] External access point limits
- [ ] FIPS 140-2 validated crypto
- [ ] TLS configuration (version, ciphers)
- [ ] VPN configuration
- [ ] Data-at-rest encryption
- [ ] Key management documentation
- [ ] DNS security
- [ ] DoS/DDoS protection
- [ ] Split tunneling prevention
- [ ] Controlled egress point
- [ ] Process memory separation
- [ ] Collaboration device policies
- [ ] Active/executable content controls
- [ ] Spam filter configuration
- [ ] Input validation
- [ ] Error message suppression

---

## 17. SDLC & Secure Development

### File patterns
```
docs/**/sdlc*.md, docs/**/development*.md
.github/**, .gitlab-ci.yml, Jenkinsfile
CONTRIBUTING.md, DEVELOPMENT.md
**/PULL_REQUEST_TEMPLATE*
.github/CODEOWNERS
tests/**, **/tests/**, spec/**, **/spec/**
```

### Code patterns for generation
```
# Testing
**/phpunit.xml, **/jest.config.*, **/pytest.ini
**/mocha*, **/.nycrc, **/coverage/**
Grep: "test", "spec", "assert", "expect", "mock"

# Security engineering principles
Grep: "least.*privilege", "defense.*in.*depth", "fail.*secure"
Grep: "separation.*duties", "minimize.*attack"

# Defect tracking
Grep: "bug", "defect", "vulnerability", "security.*issue"
.github/ISSUE_TEMPLATE/**
```

### Sub-items to check
- [ ] Written SDLC document
- [ ] Security requirements in design docs
- [ ] Security engineering principles applied
- [ ] Interface/endpoint/port/service inventory
- [ ] Developer defect tracking records
- [ ] Change management records
- [ ] Pre-production testing evidence
- [ ] Criticality analysis at SDLC decision points
- [ ] Development process review records
- [ ] Acquisition contracts with security requirements
- [ ] Test results for acquired products
- [ ] Supply chain risk assessments for developers

---

## 18. Supply Chain Risk Management

### File patterns
```
docs/**/supply-chain*.md, docs/**/scrm*.md, docs/**/sr-*.md
**/SECURITY.md, **/SUPPLY_CHAIN*.*
```

### Code patterns for generation
```
# Dependency tracking
composer.lock, package-lock.json, Pipfile.lock, Cargo.lock
**/dependabot.yml, **/renovate.json

# Vendor assessment
Grep: "vendor.*assessment", "supply.*chain", "third.*party.*risk"
```

### Sub-items to check
- [ ] SCRM Plan
- [ ] SCRM team roster
- [ ] Supply chain risk assessments
- [ ] Acquisition contracts with security requirements
- [ ] Incident notification agreements
- [ ] Anti-tamper mechanisms
- [ ] Counterfeit detection procedures
- [ ] End-of-life disposition records
- [ ] Vendor support status tracking
- [ ] Awaiting/returning components config mgmt

---

## 19. Interconnection & External Services

### File patterns
```
docs/**/interconnection*.md, docs/**/isa-*.md, docs/**/mou*.*
docs/**/external*.md, docs/**/integration*.*
```

### Code patterns for generation
```
# External connections
.env.sample (look for external URLs, API endpoints)
Grep: "api.*url", "endpoint", "external.*service", "third.*party"
Grep: "soap", "rest", "graphql", "webhook"

# Service connections
docker-compose.yml (external service dependencies)
**/Deployment.yaml (external service references)
```

### Sub-items to check
- [ ] ISAs, MOUs, SLAs for external connections
- [ ] Internal connection documentation
- [ ] Security assessments for external providers
- [ ] FedRAMP authorization evidence for providers
- [ ] Functions/ports/protocols from each provider
- [ ] Managed interfaces for telecom services
- [ ] Portable storage restrictions on external systems

---

## 20. Risk Assessment & Categorization

### File patterns
```
docs/**/risk*.md, docs/**/ra-*.md
docs/**/fips-199*.*, docs/**/categoriz*.*
docs/**/assessment*.md
```

### Code patterns for generation
```
Grep: "fips.*199", "security.*categori", "impact.*level"
Grep: "confidentiality", "integrity", "availability"
Grep: "low.*moderate.*high", "risk.*assess"
```

### Sub-items to check
- [ ] FIPS-199 categorization (C/I/A impact levels with rationale)
- [ ] Risk assessment report (threats, vulnerabilities, likelihood, impact)
- [ ] Supply chain risk assessment
- [ ] Criticality analysis
- [ ] Risk response documentation
- [ ] Risk results reported to management
- [ ] Continuous monitoring plan
