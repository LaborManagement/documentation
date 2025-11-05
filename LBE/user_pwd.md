# 🔐 Seed Users & Passwords

**Created:** November 3, 2025  
**Environment:** Development/Testing  
**Status:** 2 Bootstrap Seed Users Created

---

## 📋 Bootstrap User Credentials (Phase 1: Onboarding)

### 1. Business Administrator
| Field | Value |
|-------|-------|
| **Username** | `business.admin` |
| **Email** | business.admin@system.local |
| **Password** | `tech123` |
| **Roles** | BUSINESS_ADMIN + BASIC_USER |
| **Status** | ✅ Enabled |
| **Purpose** | User management, role assignment, business operations |

### 2. Technical Bootstrap Administrator
| Field | Value |
|-------|-------|
| **Username** | `tech.bootstrap` |
| **Email** | tech.bootstrap@system.local |
| **Password** | `tech123` |
| **Roles** | TECHNICAL_BOOTSTRAP + BASIC_USER |
| **Status** | ✅ Enabled |
| **Purpose** | System configuration, policy management, capability setup, endpoint registration |

---

## 🔑 Quick Reference Table (Phase 1 Bootstrap)

| # | Username | Password | Primary Role | Email | Created |
|---|----------|----------|--------------|-------|---------|
| 1 | `business.admin` | `tech123` | BUSINESS_ADMIN | business.admin@system.local | 2025-11-03 |
| 2 | `tech.bootstrap` | `tech123` | TECHNICAL_BOOTSTRAP | tech.bootstrap@system.local | 2025-11-03 |

*Both bootstrap users use the same password: `tech123` for development/testing*

---

## 🧪 Test Credentials (For Testing)

Both bootstrap users now use the password `tech123` for easier testing and development.

| Username | Password | Role | Status |
|----------|----------|------|--------|
| `business.admin` | `tech123` | BUSINESS_ADMIN + BASIC_USER | ✅ Active |
| `tech.bootstrap` | `tech123` | TECHNICAL_BOOTSTRAP + BASIC_USER | ✅ Active |

**Note:** All bootstrap users currently share the same bcrypt password hash ($2a$10$) for testing purposes.

**Password Generation:** Both passwords are hashed using bcrypt with cost factor 10.

---

## 🔐 Bcrypt Hash Reference

### Phase 1 Bootstrap Users (Current Implementation)
| Username | Bcrypt Hash | Password | Generated With |
|----------|-------------|----------|-----------------|
| `business.admin` | `$2a$10$iAsGHtarbe7WWpbix.0jH.tdg39z46n/jRU1GBVqFQ0n3XkIS3sqq` | `tech123` | Spring BCryptPasswordEncoder (cost=10) |
| `tech.bootstrap` | `$2a$10$iAsGHtarbe7WWpbix.0jH.tdg39z46n/jRU1GBVqFQ0n3XkIS3sqq` | `tech123` | Spring BCryptPasswordEncoder (cost=10) |

**Hash Generation Method:** Spring Security's BCryptPasswordEncoder with default strength (cost factor 10)

**Login Status:** ✅ Both users can successfully authenticate with password `tech123`

---

## 📝 Historical Reference: Phase 0 Users (Deprecated)

*The following 7 users were used in the earlier onboarding model and are now deprecated. They are kept here for reference only.*

### 1. Platform Bootstrap User (DEPRECATED)
| Field | Value |
|-------|-------|
| **Username** | `platform.bootstrap` |
| **Email** | bootstrap@system.local |
| **Password** | `Bootstrap!2025` |
| **Role** | PLATFORM_BOOTSTRAP |
| **Status** | ❌ Removed (Replaced by tech.bootstrap) |

### 2. Tech Administrator (DEPRECATED)
| Field | Value |
|-------|-------|
| **Username** | `admin.tech` |
| **Email** | admin.tech@system.local |
| **Password** | `AdminTech!2025` |
| **Role** | ADMIN_TECH |
| **Status** | ❌ Removed (Replaced by tech.bootstrap) |

### 3. Operations Administrator (DEPRECATED)
| Field | Value |
|-------|-------|
| **Username** | `admin.ops` |
| **Email** | admin.ops@system.local |
| **Password** | `AdminOps!2025` |
| **Role** | ADMIN_OPS |
| **Status** | ❌ Removed |

### 4. Board Member (DEPRECATED)
| Field | Value |
|-------|-------|
| **Username** | `board1` |
| **Email** | board1@company.local |
| **Password** | `Board!2025` |
| **Role** | BOARD |
| **Status** | ❌ Removed |

### 5. Employer Staff (DEPRECATED)
| Field | Value |
|-------|-------|
| **Username** | `employer1` |
| **Email** | employer1@company.local |
| **Password** | `Employer!2025` |
| **Role** | EMPLOYER |
| **Status** | ❌ Removed |

### 6. Worker/Employee (DEPRECATED)
| Field | Value |
|-------|-------|
| **Username** | `worker1` |
| **Email** | worker1@company.local |
| **Password** | `Worker!2025` |
| **Role** | WORKER |
| **Status** | ❌ Removed |

### 7. QA/Test User (DEPRECATED)
| Field | Value |
|-------|-------|
| **Username** | `test.user` |
| **Email** | test.user@system.local |
| **Password** | `TestUser!2025` |
| **Role** | TEST_USER |
| **Status** | ❌ Removed |

---

## ⚠️ Important Security Notes

### Development/Testing Only
- ✅ These passwords are **TEST/DEMO credentials**
- ✅ Change them **immediately in production**
- ✅ Never commit plain text passwords to version control
- ✅ Use environment variables or secret management systems

### Password Handling
- All passwords are stored as **bcrypt hashes** in the database
- Plain text passwords shown above are for **login only**
- Cannot retrieve plain text from database (one-way hashing)
- Use bcrypt hashing when updating passwords

### PLATFORM_BOOTSTRAP User
⚠️ **CRITICAL**: After system initialization is complete:
```sql
UPDATE auth.users 
SET is_enabled = false 
WHERE username = 'platform.bootstrap';
```

### Changing Passwords
To change a user's password, use bcrypt hashing:
```sql
-- Example: Change password for admin.tech
UPDATE auth.users 
SET password = '<new_bcrypt_hash>', updated_at = NOW()
WHERE username = 'admin.tech';
```

---

## 📊 User Capabilities Summary

| Role | Users | Capabilities | Access Level |
|------|-------|--------------|--------------|
| PLATFORM_BOOTSTRAP | 1 | 54 (55%) | Full System |
| ADMIN_TECH | 1 | 49 (50%) | Technical Admin |
| ADMIN_OPS | 1 | 30 (31%) | Operations Admin |
| BOARD | 1 | 15 (15%) | Board Level |
| EMPLOYER | 1 | 16 (16%) | Organization-Scoped |
| WORKER | 1 | 10 (10%) | User-Scoped (Read-Only) |
| TEST_USER | 1 | 51 (52%) | Comprehensive Testing |

---

## 🔍 VPD (Virtual Private Data) Configuration

### Access Scopes
- **WORKER (worker1):** Read-only access to EMP-001
- **EMPLOYER (employer1):** Read+Write access to EMP-001
- **BOARD (board1):** Full board-level access (BOARD-DEFAULT)
- **ADMIN_TECH (admin.tech):** Full board-level access (BOARD-DEFAULT)
- **ADMIN_OPS (admin.ops):** Full board-level access (BOARD-DEFAULT)

### Board & Employer IDs
```
Board ID: BOARD-DEFAULT
Employer ID: EMP-001
```

*Note: Replace with actual identifiers in production*

---

## 📝 Database Details

| Detail | Value |
|--------|-------|
| **Host** | localhost |
| **Port** | 5432 |
| **Database** | labormanagement |
| **Schema** | auth |
| **Docker Container** | labormanagement |

---

## ✅ Setup Verification Results

- ✅ 7 Roles Created
- ✅ 89 Capabilities Configured
- ✅ 7 Policies Created
- ✅ 225 Policy-Capability Links
- ✅ 7 Seed Users Created
- ✅ 7 User-Role Assignments
- ✅ 13 VPD Entries Configured
- ✅ All seed user passwords verified and working

---

## 🔐 Authentication Status

| Username | Endpoint | Status | Verified Date |
|----------|----------|--------|----------------|
| `platform.bootstrap` | `/api/auth/login` | ✅ Working | 2025-11-02 |
| `admin.tech` | `/api/auth/login` | ✅ Working | 2025-11-02 |
| `admin.ops` | `/api/auth/login` | ✅ Working | 2025-11-02 |
| `board1` | `/api/auth/login` | ✅ Working | 2025-11-02 |
| `employer1` | `/api/auth/login` | ✅ Working | 2025-11-02 |
| `worker1` | `/api/auth/login` | ✅ Working | 2025-11-02 |
| `test.user` | `/api/auth/login` | ✅ Working | 2025-11-02 |

**Password Encoding:** All passwords stored as bcrypt hashes (algorithm: $2a$, strength: 10)

---

## 🚀 Next Steps

1. ✅ Test login with one of the seed users
2. ✅ Disable PLATFORM_BOOTSTRAP user after setup
3. ✅ Change default passwords in production
4. ✅ Update board/employer IDs with actual values
5. ✅ Register API endpoints and UI pages
6. ✅ Add performance indexes to `user_tenant_acl`
7. ✅ Monitor system logs and audit trails

---

**Last Updated:** 2025-11-02 16:30:00 UTC  
**Created By:** SQL Onboarding Scripts + Authentication Verification  
**Environment:** Development  
**Authentication Status:** All 7 seed users verified working with `/api/auth/login` endpoint
