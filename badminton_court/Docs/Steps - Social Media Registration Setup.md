# Social Media Registration Setup Guide
Source file: badminton_court/Docs/Steps - Social Media Registration Setup.md

This guide explains how to configure social media registration (Google, Facebook, Twitter) for the Badminton Court Management System using django-allauth.

## Table of Contents
- [Prerequisites](#prerequisites)
- [Overview](#overview)
- [Google OAuth Setup](#google-oauth-setup)
- [Facebook OAuth Setup](#facebook-oauth-setup)
- [Twitter OAuth Setup](#twitter-oauth-setup)
- [Django Configuration](#django-configuration)
- [Environment Variables](#environment-variables)
- [Testing the Setup](#testing-the-setup)
- [Troubleshooting](#troubleshooting)

## Prerequisites

- Django project with django-allauth installed
- Admin access to Django admin panel
- Developer accounts with Google, Facebook, and Twitter
- Domain name or localhost for development

## Overview

The Badminton Court Management System uses django-allauth for authentication, including social media OAuth providers. This allows users to sign up and log in using their existing Google, Facebook, or Twitter accounts.

**Note:** Instagram is not included in django-allauth by default and requires custom provider implementation.

## Google OAuth Setup

**Important:** You must perform these steps in the exact order listed. If you try to create credentials before configuring the consent screen, the Google Cloud Console will block you.

### Step 1: Configure OAuth Consent Screen

1. Go to [Google Cloud Console](https://console.cloud.google.com/).
2. Select your project from the project dropdown.
3. In the left-hand sidebar, navigate to **APIs & Services** > **OAuth consent screen**.
4. If asked, choose **External** and click **Create**.
5. **App Information:**
   - **App name:** Enter a recognizable name (e.g., "Badminton Court Management").
   - **User support email:** Select your email address.
   - **Developer contact information:** Enter your email address.
   - Click **Save and Continue**.
6. **Scopes:**
   - Click **Add or Remove Scopes**.
   - Ensure `.../auth/userinfo.email` and `.../auth/userinfo.profile` (or the basic `email` and `profile` scopes) are added.
   - Click **Update** and then **Save and Continue**.
7. **Test Users:** (Optional) Add your email as a test user if you are in "Testing" mode.
8. **Summary:** Review and click **Back to Dashboard**.

### Step 2: Create OAuth 2.0 Credentials

1. In the left-hand sidebar, navigate to **APIs & Services** > **Credentials**.
2. Click **+ Create Credentials** at the top.
3. Select **OAuth client ID** from the dropdown menu.
4. If you see the message "You haven't configured any OAuth clients for this project yet" or are prompted to configure the consent screen, make sure you completed **Step 1** above.
5. **Application type:** Select **Web application**.
6. **Name:** Enter a name (e.g., "Web Client").
7. **Authorized redirect URIs:** Click **+ Add URI** and add all your environment callback URLs:
   - `http://localhost:8000/accounts/google/login/callback/`
   - `https://humrine.com/court/accounts/google/login/callback/`
   - `https://humrine.com/court-staging/accounts/google/login/callback/`
   - `https://app.humrine.com/accounts/google/login/callback/`
   - `https://staging.humrine.com/accounts/google/login/callback/`
8. Click **Create**.
9. A dialog will appear with your **Client ID** and **Client Secret**. Copy these immediately and save them securely.

### Step 3: Configure in Django

Add the following to your environment variables (ensure they match your `.env` configuration):
```bash
GOOGLE_CLIENT_ID=your-google-client-id
GOOGLE_CLIENT_SECRET=your-google-client-secret
```

## Facebook OAuth Setup

### Step 1: Create Facebook App

1. Go to [Facebook Developers](https://developers.facebook.com/)
2. Click "Create App"
3. Follow the multi-step creation process:
   - **App details**: Enter app name (e.g., "Badminton Court") and contact email
   - **Use cases**: Select the use cases that apply (note: "Authenticate and request data from users with Facebook Login" may not be available initially)
   - **Business**: Create or connect a business portfolio (required for verification)
   - **Requirements**: Review and click Next
   - **Overview**: Click "Create app"
4. After creation, you may be redirected to the Business portfolio page

**Note:** For detailed step-by-step instructions with screenshots, see [Steps - Creating a Facebook App.md](./Steps%20-%20Creating%20a%20Facebook%20App.md)

### Step 2: Navigate to App Dashboard

1. From the Business portfolio page, look for a menu or navigation bar
2. Click on "Apps" or "My Apps" to see your list of apps
3. Click on your app name "Badminton Court" to open the App Dashboard
4. Alternatively, go directly to [Facebook App Dashboard](https://developers.facebook.com/apps/)
5. Select "Badminton Court" from the list of apps

**Important:** The Business Portfolio page is different from the App Dashboard. You must navigate to the specific app's dashboard to configure Facebook Login.

### Step 3: Add Facebook Login Product

**Note:** Facebook has updated their dashboard to use Meta AI. The interface may differ from traditional "Add Product" workflows.

**Option 1: Using Meta AI Assistant**
1. In the app dashboard, look for a Meta AI chat or assistant interface
2. Type or select: "Add Facebook Login" or "Set up Facebook Login"
3. Follow the AI-guided prompts to add the Facebook Login product

**Option 2: Using Traditional Menu (if available)**
1. In the app dashboard, look for a left sidebar or navigation menu
2. Click "Add Product" or search for "Facebook Login"
3. Select "Facebook Login" from the available products
4. Click "Set Up" or "Add"

**Option 3: Using App Settings**
1. Navigate to "App Settings" or "Products" section
2. Look for "Facebook Login" in the available products list
3. Click "Set Up" or "Configure" next to Facebook Login

### Step 4: Configure Facebook Login Settings

1. Navigate to Facebook Login > Settings
2. Configure the following:
   - **Client OAuth Login**: Enable
   - **Web OAuth Login**: Enable
   - **Enforce HTTPS**: Enable for production, can be disabled for development
   - **Use Strict Mode for Redirect URIs**: Enable (recommended)
3. Click "Save Changes"

### Step 5: Configure Redirect URIs

1. In the Facebook Login Settings, find "Valid OAuth Redirect URIs"
2. Add the following URIs based on your environment:
   - Development: `http://localhost:8000/accounts/facebook/login/callback/`
   - Staging: `https://your-staging-domain.com/accounts/facebook/login/callback/`
   - Production: `https://your-production-domain.com/accounts/facebook/login/callback/`
3. Click "Save Changes"

### Step 6: Get App ID and App Secret

1. In the app dashboard, click "Settings" > "Basic"
2. Copy the **App ID** (this is your `SOCIAL_AUTH_FACEBOOK_KEY`)
3. Click "Show" next to **App Secret** to reveal it (this is your `SOCIAL_AUTH_FACEBOOK_SECRET`)
4. Save both values securely

### Step 7: Configure in Django

Add the following to your environment variables:
```bash
SOCIAL_AUTH_FACEBOOK_KEY=your-facebook-app-id
SOCIAL_AUTH_FACEBOOK_SECRET=your-facebook-app-secret
```

## Twitter OAuth Setup

### Step 1: Create Twitter Developer Account

1. Go to [Twitter Developer Portal](https://developer.twitter.com/)
2. Create a developer account
3. Create a new app/project

### Step 2: Configure OAuth Settings

1. Navigate to your app settings
2. Go to "Authentication settings"
3. Enable OAuth 2.0
4. Configure callback URLs:
   - Development: `http://localhost:8000/accounts/twitter/login/callback/`
   - Staging: `https://your-staging-domain.com/accounts/twitter/login/callback/`
   - Production: `https://your-production-domain.com/accounts/twitter/login/callback/`
5. Generate Client ID and Client Secret

### Step 3: Configure in Django

Add the following to your environment variables:
```bash
SOCIAL_AUTH_TWITTER_KEY=your-twitter-client-id
SOCIAL_AUTH_TWITTER_SECRET=your-twitter-client-secret
```

## Django Configuration

### Settings Configuration

Ensure the following is configured in `badminton_court/settings/base.py`:

```python
INSTALLED_APPS = [
    # ...
    'django.contrib.sites',
    'allauth',
    'allauth.account',
    'allauth.socialaccount',
    'allauth.socialaccount.providers.google',
    'allauth.socialaccount.providers.facebook',
    'allauth.socialaccount.providers.twitter',
    # ...
]

AUTHENTICATION_BACKENDS = [
    # Needed to login by username in Django admin, regardless of `allauth`
    'django.contrib.auth.backends.ModelBackend',
    
    # `allauth` specific authentication methods, such as login by e-mail
    'allauth.account.auth_backends.AuthenticationBackend',
]

SITE_ID = 1  # Required by django-allauth
```

### URL Configuration

Ensure the following is in `badminton_court/urls.py`:

```python
urlpatterns = [
    # ...
    path('accounts/', include('allauth.urls')),
    # ...
]
```

### Social Account Settings

Add to `badminton_court/settings/base.py`:

```python
# Social account settings
SOCIALACCOUNT_PROVIDERS = {
    'google': {
        'SCOPE': [
            'profile',
            'email',
        ],
        'AUTH_PARAMS': {
            'access_type': 'offline',
        }
    },
    'facebook': {
        'METHOD': 'oauth2',
        'SCOPE': ['email', 'public_profile'],
        'AUTH_PARAMS': {'auth_type': 'reauthenticate'},
        'FIELDS': [
            'id',
            'first_name',
            'last_name',
            'middle_name',
            'name',
            'email',
        ]
    },
    'twitter': {
        'SCOPE': ['tweet.read', 'users.read'],
    }
}
```

### Account Settings

Add to `badminton_court/settings/base.py`:

```python
# Account settings
ACCOUNT_EMAIL_REQUIRED = True
ACCOUNT_USERNAME_REQUIRED = False
ACCOUNT_AUTHENTICATION_METHOD = 'email'
ACCOUNT_EMAIL_VERIFICATION = 'mandatory'  # or 'optional' or 'none'
```

## Environment Variables

Add the following to your `.env.dev`, `.env.staging`, and `.env.production` files:

```bash
# Google OAuth
SOCIAL_AUTH_GOOGLE_OAUTH2_KEY=your-google-client-id
SOCIAL_AUTH_GOOGLE_OAUTH2_SECRET=your-google-client-secret

# Facebook OAuth
SOCIAL_AUTH_FACEBOOK_KEY=your-facebook-app-id
SOCIAL_AUTH_FACEBOOK_SECRET=your-facebook-app-secret

# Twitter OAuth
SOCIAL_AUTH_TWITTER_KEY=your-twitter-client-id
SOCIAL_AUTH_TWITTER_SECRET=your-twitter-client-secret
```

**Important:** Never commit these secrets to version control. Use environment-specific `.env` files and encryption for production.

## Testing the Setup

### 1. Verify Configuration

Run the Django shell and check provider configuration:

```bash
python manage.py shell
```

```python
from allauth.socialaccount import providers
from allauth.socialaccount.providers import registry

# List all available providers
print(registry.get_list())
```

### 2. Test Signup Flow

1. Navigate to the signup page: `http://localhost:8000/accounts/signup/`
2. Click on the social media button (Google, Facebook, or Twitter)
3. Complete the OAuth flow on the provider's site
4. Verify redirect back to your application
5. Check that the user account was created

### 3. Test Login Flow

1. Navigate to the login page: `http://localhost:8000/accounts/login/`
2. Click on the social media button
3. Complete the OAuth flow
4. Verify successful login

### 4. Check Django Admin

1. Log in to Django admin: `http://localhost:8000/admin/`
2. Navigate to "Social accounts" section
3. Verify that social accounts are being linked correctly

## Troubleshooting

### Issue: Social media buttons not visible

**Cause:** Provider not configured or environment variables missing.

**Solution:**
1. Check that `SOCIAL_AUTH_*` environment variables are set
2. Verify provider is in `INSTALLED_APPS`
3. Restart the Django server after adding environment variables

### Issue: OAuth redirect URI mismatch

**Cause:** Redirect URI in provider console doesn't match Django settings.

**Solution:**
1. Check the exact URL in the error message
2. Update the redirect URI in the provider's developer console
3. Ensure the protocol (http vs https) matches

### Issue: Email verification not working

**Cause:** Email backend not configured or email verification disabled.

**Solution:**
1. Configure email backend in Django settings
2. Set `ACCOUNT_EMAIL_VERIFICATION = 'mandatory'`
3. Test email sending with Django's send_mail function

### Issue: User account not created after OAuth

**Cause:** Auto-signup disabled or missing required fields.

**Solution:**
1. Set `SOCIALACCOUNT_AUTO_SIGNUP = True` in settings
2. Ensure email is in the OAuth scope
3. Check Django logs for errors

### Issue: Instagram not available

**Cause:** Instagram is not included in django-allauth by default.

**Solution:**
Instagram requires a custom provider implementation. Consider using Facebook OAuth instead, which is supported out of the box.

### Issue: CORS errors in production

**Cause:** Domain not whitelisted in provider console.

**Solution:**
1. Add your production domain to the authorized domains in the provider's developer console
2. Ensure SSL is enabled for production OAuth flows

## Additional Resources

- [django-allauth Documentation](https://django-allauth.readthedocs.io/)
- [Google OAuth 2.0 Documentation](https://developers.google.com/identity/protocols/oauth2)
- [Facebook Login Documentation](https://developers.facebook.com/docs/facebook-login/)
- [Twitter OAuth 2.0 Documentation](https://developer.twitter.com/en/docs/authentication/oauth-2-0)

## Security Best Practices

1. **Never commit secrets to version control** - Use environment variables and encryption
2. **Use HTTPS in production** - OAuth requires secure connections
3. **Limit OAuth scopes** - Only request the permissions you actually need
4. **Regularly rotate secrets** - Update client secrets periodically
5. **Monitor social account links** - Review linked accounts in Django admin regularly
6. **Enable email verification** - Prevent spam accounts by requiring email verification

## Support

If you encounter issues not covered in this guide:
1. Check Django logs for detailed error messages
2. Verify all environment variables are correctly set
3. Ensure provider credentials are valid and not expired
4. Review the provider's developer console for any app restrictions or warnings
