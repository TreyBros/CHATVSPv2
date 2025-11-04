# Rebranding Plan: Onyx → ChatVSP (Frontend Only)

## Overview
This document outlines the complete plan to rebrand the Onyx application to "ChatVSP" in the frontend UI only, without touching any backend code, API references, or configurations that could break functionality.

---

## Changes Required

### 1. Replace Logo Assets (7 files)
**Location:** `/web/public/`

Replace these image files with ChatVSP branded equivalents (maintain same filenames and dimensions):

1. `onyx.ico` - Favicon (browser tab icon)
2. `logo.png` - Main logo image (blue checkmark/heart logo provided)
3. `logo.svg` - Main logo vector (needs conversion from PNG)
4. `logo-dark.png` - Dark theme logo (needs creation)
5. `logotype.png` - Full logotype with text (needs creation)
6. `logotype-dark.png` - Dark theme logotype (needs creation)

**Action Required:** Convert the provided logo.png (blue checkmark/heart design) to SVG format and create dark theme and logotype variations.

---

### 2. Update UI Text (13 files, ~30 text occurrences)

#### High Priority - Direct UI Display:

**File 1: `/web/src/app/layout.tsx`**
- **Line 61:** Page title metadata
- Change: `title: enterpriseSettings?.application_name || "Onyx",`
- To: `title: enterpriseSettings?.application_name || "ChatVSP",`

**File 2: `/web/src/components/initialSetup/welcome/WelcomeModal.tsx`**
- **Line 65:** Modal title
  - Change: `title={"Welcome to Onyx!"}`
  - To: `title={"Welcome to ChatVSP!"}`
- **Line 70:** Description text
  - Change: `Onyx brings all your company&apos;s knowledge...`
  - To: `ChatVSP brings all your company&apos;s knowledge...`
- **Line 75:** Description text
  - Change: `This key allows Onyx to interact with the AI model,`
  - To: `This key allows ChatVSP to interact with the AI model,`

**File 3: `/web/src/app/auth/login/LoginText.tsx`**
- **Line 13:** Login page welcome text
  - Change: `{(settings && settings?.enterpriseSettings?.application_name) || "Onyx"}`
  - To: `{(settings && settings?.enterpriseSettings?.application_name) || "ChatVSP"}`

**File 4: `/web/src/components/auth/AuthFlowContainer.tsx`**
- **Line 23:** New user signup text
  - Change: `New to Onyx?{" "}`
  - To: `New to ChatVSP?{" "}`

**File 5: `/web/src/components/OnyxInitializingLoader.tsx`**
- **Line 12:** Loading screen text
  - Change: `Initializing {settings?.enterpriseSettings?.application_name ?? "Onyx"}`
  - To: `Initializing {settings?.enterpriseSettings?.application_name ?? "ChatVSP"}`

**File 6: `/web/src/refresh-components/Logo.tsx`**
- **Line 52:** "Powered by" branding text
  - Change: `Powered by Onyx`
  - To: `Powered by ChatVSP`

**File 7: `/web/src/refresh-components/AgentCard.tsx`**
- **Line 127:** Default agent owner display
  - Change: `{agent.owner?.email || "Onyx"}`
  - To: `{agent.owner?.email || "ChatVSP"}`

**File 8: `/web/src/app/chat/components/ChatPopup.tsx`**
- **Line 37:** Welcome popup title
  - Change: `: \`Welcome to ${enterpriseSettings?.application_name || "Onyx"}!\`);`
  - To: `: \`Welcome to ${enterpriseSettings?.application_name || "ChatVSP"}!\`);`

**File 9: `/web/src/app/chat/components/input/ChatInputBar.tsx`**
- **Line 449:** Chat input placeholder text
  - Change: `"Onyx"`
  - To: `"ChatVSP"`

**File 10: `/web/src/app/chat/shared/[chatId]/SharedChatDisplay.tsx`**
- **Line 32:** Back link text
  - Change: `Back to {enterpriseSettings?.application_name || "Onyx Chat"}`
  - To: `Back to {enterpriseSettings?.application_name || "ChatVSP Chat"}`

**File 11: `/web/src/app/chat/nrf/NRFPage.tsx`**
- **Line 359:** Welcome header
  - Change: `Welcome to Onyx`
  - To: `Welcome to ChatVSP`

**File 12: `/web/src/components/chat/FederatedOAuthModal.tsx`**
- **Line 147:** Application name reference
  - Change: `settings?.enterpriseSettings?.application_name || "Onyx";`
  - To: `settings?.enterpriseSettings?.application_name || "ChatVSP";`

**File 13: `/web/src/app/ee/admin/whitelabeling/WhitelabelingForm.tsx`**
- **Line 143:** Help text (3 occurrences)
  - Change: `The custom name you are giving Onyx for your team. This will replace 'Onyx' everywhere in the UI.`
  - To: `The custom name you are giving ChatVSP for your team. This will replace 'ChatVSP' everywhere in the UI.`
- **Line 144:** Placeholder text
  - Change: `placeholder="Custom name which will replace 'Onyx'"`
  - To: `placeholder="Custom name which will replace 'ChatVSP'"`
- **Line 183:** Help text
  - Change: `Specify your own logo to replace the standard Onyx logo.`
  - To: `Specify your own logo to replace the standard ChatVSP logo.`
- **Line 242:** Popup header text
  - Change: `values.application_name || "Onyx"`
  - To: `values.application_name || "ChatVSP"`

---

### 3. Update Configuration Text (3 files)

**File 1: `/web/src/lib/connectors/connectors.tsx`**
- **Line 385-386:** Google Drive connector description
  - Change: `"This will allow Onyx to index everything in the shared drives..."`
  - To: `"This will allow ChatVSP to index everything in the shared drives..."`
- **Line 400-401:** Google Drive My Drives description
  - Change: `"This will allow Onyx to index everything in your My Drive..."`
  - To: `"This will allow ChatVSP to index everything in your My Drive..."`
- **Line 409:** Files shared with you description
  - Change: `"This will allow Onyx to index all files shared with you."`
  - To: `"This will allow ChatVSP to index all files shared with you."`
- **Line 719:** Salesforce connector description
  - Change: `"...and Onyx will default to indexing by 'Account'."`
  - To: `"...and ChatVSP will default to indexing by 'Account'."`

**File 2: `/web/src/refresh-components/onboarding/constants.tsx`**
- **Line 71:** Web search description
  - Change: `description: "Enable Onyx to search the internet for information."`
  - To: `description: "Enable ChatVSP to search the internet for information."`
- **Lines 125, 147, 170, 193, 216, 238:** Model descriptions (6 occurrences)
  - Change: `"This model will be used by Onyx by default for..."`
  - To: `"This model will be used by ChatVSP by default for..."`

**File 3: `/web/src/refresh-components/onboarding/steps/NameStep.tsx`**
- **Line 49:** Onboarding question
  - Change: `What should Onyx call you?`
  - To: `What should ChatVSP call you?`

---

## What Will NOT Change

### Backend Code (Excluded by Requirement)
- All files in `/backend` directory
- Docker configurations
- Environment variable names
- API endpoint URLs or paths
- Database references

### TypeScript Interfaces/Types (Internal Code Structure)
- `/web/src/lib/search/interfaces.ts` - Lines 55, 60, 76, 80, 85, 89, 114, 169
  - Interface names: `OnyxDocument`, `MinimalOnyxDocument`, etc.
  - **Reason:** Internal code structure; changing would break API contracts

### Component/File Names
- `/web/src/components/OnyxInitializingLoader.tsx` (filename)
- `/web/src/icons/onyx-logo.tsx` (filename)
- `/web/src/icons/onyx-octagon.tsx` (filename)
- **Reason:** Renaming requires updating all imports throughout codebase

### Icon Component Names (Internal References)
- `/web/src/components/icons/icons.tsx`
  - Component exports like `OnyxIcon`, `OnyxLogoTypeIcon`
  - **Reason:** React component names used in imports

### SVG Component Internal Names
- `/web/src/icons/onyx-logo.tsx` - `const OnyxLogo`
- `/web/src/icons/onyx-octagon.tsx` - `const SvgOnyxOctagon`
- **Reason:** Internal constant names, not displayed to users

### Test Files
- All files in `/web/tests/` directory
- **Reason:** Test utilities and fixtures, not user-facing

### Build/Config Files
- `/web/next.config.js`
- `/web/package.json`
- `/web/Dockerfile`
- **Reason:** Build configuration, not user-facing

### Documentation
- `/web/README.md`
- `/web/STANDARDS.md`
- **Reason:** Developer documentation (can be updated separately if desired)

### Comment/Code Variables
- Code comments and internal variable names
- **Reason:** Not displayed to users

---

## Summary

| Category | Count | Details |
|----------|-------|---------|
| **UI Text Changes** | 13 files | ~30 text occurrences (Onyx → ChatVSP) |
| **Logo Asset Replacements** | 6 files | All image files in /web/public/ |
| **Favicon Replacement** | 1 file | onyx.ico |
| **Configuration Text** | 3 files | Connector descriptions, onboarding |
| **Total Frontend Files** | **17 files** | |
| **Files Excluded** | 119+ files | Internal/technical references |

---

## Execution Steps

1. **Prepare Logo Assets**
   - Convert provided logo.png (blue checkmark/heart design) to SVG format
   - Create dark theme variant (logo-dark.png)
   - Create logotype versions with "ChatVSP" text (logotype.png, logotype-dark.png)
   - Create favicon from logo (onyx.ico)
   - Replace all 7 image files in `/web/public/`

2. **Update UI Text Files**
   - Make changes to all 13 UI text files
   - Replace "Onyx" with "ChatVSP" in all specified locations
   - Update in order of user visibility

3. **Update Configuration Text**
   - Update connector descriptions (replace Onyx with ChatVSP)
   - Update onboarding text (replace Onyx with ChatVSP)

4. **Testing & Verification**
   - Verify all changed text appears correctly in UI
   - Test that no functionality is broken
   - Check all logo displays work correctly
   - Test both light and dark themes

5. **Optional: Enterprise Whitelabeling**
   - Set up custom application name "ChatVSP" through admin panel as fallback

---

## Notes

- All changes are frontend-only and will not affect backend functionality
- Internal code structure, API contracts, and database schemas remain unchanged
- The application will continue to function identically, just with new "ChatVSP" branding
- Custom enterprise whitelabeling settings will take precedence over these defaults if configured
- Logo file provided: Blue checkmark/heart design (logo.png) - requires conversion to other formats
