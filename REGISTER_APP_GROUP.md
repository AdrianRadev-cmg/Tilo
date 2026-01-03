# Register App Group - Quick Steps

## The Problem
Xcode can't create provisioning profiles because the App Group `group.com.adriyanradev.Tilo` isn't registered in Apple Developer portal.

## Solution: Register App Group (5 minutes)

1. **Go to Apple Developer Portal:**
   - Visit: https://developer.apple.com/account/resources/identifiers/list/applicationGroup
   - Sign in with your Apple ID

2. **Click the "+" button** (top left)

3. **Fill in the form:**
   - **Description:** `Tilo App Group`
   - **Identifier:** `group.com.adriyanradev.Tilo` (must match exactly)
   - Click **Continue**

4. **Review and Register:**
   - Review the details
   - Click **Register**

5. **Go back to Xcode:**
   - Xcode → Settings → Accounts
   - Select your account
   - Click **Download Manual Profiles**
   - Wait for it to complete

6. **Try Distribute App again!**

---

## Alternative: Use Different App Group Name

If you want to use a different identifier, we can change it in the code. But the above is the recommended approach.

