# Steps - Creating a Facebook App
Source file: badminton_court/Docs/Steps - Creating a Facebook App.md

**Related:** [Steps - Social Media Registration Setup.md](./Steps%20-%20Social%20Media%20Registration%20Setup.md) - Complete guide for setting up Google, Facebook, and Twitter OAuth

This document provides detailed step-by-step instructions for creating a Facebook app for OAuth authentication in the Badminton Court Management System.

## Overview

When creating a new Facebook app at [developers.facebook.com/apps/creation/](https://developers.facebook.com/apps/creation/), the process involves several steps/tabs with specific configuration options.

## Step-by-Step Process

### Tab 1: App Details

- **App name**: Badminton Court
- **App contact email**: solomiosisante@gmail.com

### Tab 2: Use Cases

Select the use cases that apply to your app:

- ✅ Create & manage ads with Marketing API
- ✅ Create & manage app ads with Meta Ads Manager
- ✅ Access the Threads API
- ❌ Launch an Instant Game on Facebook and Messenger
- ❌ Authenticate and request data from users with Facebook Login
- ✅ Connect with customers through WhatsApp

**Note:** "Authenticate and request data from users with Facebook Login" may not be available initially during app creation. This will be added later as a product.

### Tab 3: Business

This step requires connecting a business portfolio to your app.

**Prompt:** "Which business portfolio do you want to connect to this app?"

> Connect a verified business portfolio to your app to get access to third-party user and business data from other business portfolios and publish this app. You can connect an unverified business portfolio or choose to add one later, but will be required to complete verification to gain data access.

**Initial State:** No businesses available.

#### Creating a New Business Portfolio

1. Click "Create a new portfolio"
2. **Business portfolio name**: Badminton Court
   - This should match the public name of your business since it will be visible across Meta
   - Cannot contain special characters

3. **Enter your contact info**:
   - **First name**: Solomio
   - **Last name**: Sisante
   - **Business email**: solomiosisante@gmail.com
     - This email will be used to contact you about your business
     - It won't be visible to your customers
     - Your contact info will be saved within this business portfolio
     - You can edit this contact info anytime in business settings

4. Accept Meta's Privacy Policy and create the portfolio

### After Creating the Portfolio

After clicking the Next button:

- **Message**: "Badminton Court was created"
- **Verification prompt**: "Verify your portfolio to help Meta understand who is creating apps on this platform. Verification is required to submit to App Review and access data owned by people outside your business. You can add people, assign roles and claim business assets in this portfolio in business settings."

**Action taken:** Clicked "Start verification" which brought me to the Business portfolio page. Closed it and went back to the Create an app page. The "Badminton Court" business portfolio now appears in the list. Selected it and clicked Next.

### Tab 4: Requirements

**Publishing requirements**: These are the steps you need to complete to get and maintain access to user and business data.

**Status**: No requirements identified. This may change if you add more to this app.

**Action taken:** Clicked Next.

### Tab 5: Overview

**Action taken:** Clicked "Create app" button.

**Result:** App created successfully and redirected to the Badminton Court Business portfolio page.

## Next Steps

After creating the Facebook app, continue with the configuration steps in the [Social Media Registration Setup Guide](./Steps%20-%20Social%20Media%20Registration%20Setup.md):

1. Navigate to the App Dashboard
2. Add Facebook Login product
3. Configure Facebook Login settings
4. Configure redirect URIs (including `http://localhost:8000/accounts/facebook/login/callback/`)
5. Get App ID and App Secret
6. Add credentials to `.env.dev` as `FACEBOOK_CLIENT_ID` and `FACEBOOK_CLIENT_SECRET`