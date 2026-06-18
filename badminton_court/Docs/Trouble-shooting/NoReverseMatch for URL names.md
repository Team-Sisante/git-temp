# NoReverseMatch for 'index' or 'profile' URL names
## Source: Docs/Trouble-shooting/NoReverseMatch for URL names.md

## Troubleshooting Django NoReverseMatch errors for hardcoded URL names

### Symptom
Two distinct `NoReverseMatch` errors:

#### Error 1: `index` URL name doesn't exist
```
NoReverseMatch at /accounts/logout/
Reverse for 'index' not found. 'index' is not a valid view function or pattern name.
In template /tmp/_MEI7UJzDQ/templates/account/logout.html, error at line 33
```

#### Error 2: `profile` URL name doesn't exist
```
NoReverseMatch at /accounts/profile/
Reverse for 'profile' not found. 'profile' is not a valid view function or pattern name.
In template /tmp/_MEI7UJzDQ/templates/court_management/base.html, error at line 68
```

### Root Cause
Templates reference URL names that don't exist in `badminton_court/urls.py`:

| Template uses | Actual URL name in urls.py |
|---------------|---------------------------|
| `{% url 'index' %}` | `home` (the homepage is registered as `name='home'`) |
| `{% url 'profile' %}` | `account_profile` (the profile page is registered as `name='account_profile'`) |

These are hardcoded URL names in templates that don't match the actual `name=` attributes in the URL patterns.

### Diagnostic Steps

1. **Find all URL names used in templates:**
   ```bash
   cd badminton_court
   grep -rohE "\{% url '[^']+' %\}" --include="*.html" . | sort -u
   ```

2. **Find all URL names defined in urls.py:**
   ```bash
   grep -oE "name='[a-z_-]+'" badminton_court/urls.py court_management/urls.py | sort -u
   ```

3. **Cross-reference** — any URL name in step 1 that's NOT in step 2 will cause `NoReverseMatch`.

4. **Find specific offending references:**
   ```bash
   grep -rn "{% url 'index' %}" --include="*.html" .
   grep -rn "{% url 'profile' %}" --include="*.html" .
   ```

### Fix

#### Fix 1: Change `{% url 'index' %}` to `{% url 'home' %}`

Find the template(s) using `'index'`:
```bash
cd badminton_court
grep -rn "{% url 'index' %}" --include="*.html" .
```

Typical result:
```
./templates/account/logout.html:33:    <a href="{% url 'index' %}" class="btn btn-outline-secondary btn-lg">
```

Edit the file and change `'index'` to `'home'`:
```html
<!-- Before -->
<a href="{% url 'index' %}" class="btn btn-outline-secondary btn-lg">

<!-- After -->
<a href="{% url 'home' %}" class="btn btn-outline-secondary btn-lg">
```

#### Fix 2: Change `{% url 'profile' %}` to `{% url 'account_profile' %}`

Find the template(s) using `'profile'`:
```bash
grep -rn "{% url 'profile' %}" --include="*.html" .
```

Typical result:
```
./court_management/templates/court_management/base.html:68:    <li><a class="dropdown-item" href="{% url 'profile' %}">Profile</a></li>
```

Edit the file and change `'profile'` to `'account_profile'`:
```html
<!-- Before -->
<li><a class="dropdown-item" href="{% url 'profile' %}">Profile</a></li>

<!-- After -->
<li><a class="dropdown-item" href="{% url 'account_profile' %}">Profile</a></li>
```

#### Step 3: Commit, rebuild, redeploy

```bash
cd badminton_court
git add templates/account/logout.html court_management/templates/court_management/base.html
git commit -m "Fix: use correct URL names ('home', 'account_profile') in templates"
git push
```

Then trigger the `badminton_court-artifacts` and `badminton_court-staging` pipelines.

### How to Audit All URL References

Run this one-liner to find ALL mismatched URL names:

```bash
cd badminton_court

# Get all URL names used in templates
USED_NAMES=$(grep -rohE "\{% url '[^']+' %\}" --include="*.html" . | sed "s/{% url '\([^']*\)' %}/\1/" | sort -u)

# Get all URL names defined in urls.py
DEFINED_NAMES=$(grep -ohE "name=['\"][a-z_-]+['\"]" badminton_court/urls.py court_management/urls.py | sed "s/name=['\"]\([^'\"]*\)['\"]/\1/" | sort -u)

# Find used names that aren't defined
echo "URL names used in templates but NOT defined in urls.py:"
comm -23 <(echo "$USED_NAMES") <(echo "$DEFINED_NAMES")
```

### Why This Happens

Common causes:
1. **Refactor left stale references** — someone renamed a URL pattern but forgot to update templates
2. **Copied from another project** — the template came from a project that used `'index'` for the homepage
3. **Convention mismatch** — allauth uses `account_profile`, but the template author assumed `profile`

### Verification

After redeployment:
```bash
# Logout page should return 200 (not 500)
curl -sk -o /dev/null -w "HTTP %{http_code}\n" https://humrine.com/court-staging/accounts/logout/

# Profile page link should point to the correct URL
curl -sk https://humrine.com/court-staging/ | grep -oE 'href="[^"]*"[^>]*>Profile'
# Expected: href="/court-staging/accounts/profile/" ...>Profile
```

### Related Files
- `badminton_court/templates/account/logout.html` — had `{% url 'index' %}`
- `badminton_court/court_management/templates/court_management/base.html` — had `{% url 'profile' %}`
- `badminton_court/badminton_court/urls.py` — defines `name='home'`
- `badminton_court/court_management/urls.py` — defines `name='account_profile'`
- See also: [Django redirects missing subpath prefix](Django%20redirects%20missing%20subpath%20prefix.md)
