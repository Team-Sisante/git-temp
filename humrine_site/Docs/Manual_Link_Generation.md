# How to Manually Add an Affiliate Link

1. **Obtain the affiliate link**  
   - Log in to your Lazada / Shopee / Involve Asia dashboard.  
   - Find the product you want to promote.  
   - Use the "Generate Link" or "Deep Link" tool to get the full affiliate URL.  
   - Copy that URL (it will contain your affiliate ID).

2. **Add it to Django**  
   - Go to your admin panel → **Affiliate** → **Tracked Affiliate Links** → **Add Tracked Affiliate Link**.  
   - Fill in:  
     * **Title:** e.g., "XYZ Wireless Mouse"  
     * **Slug:** (auto‑filled from title, e.g., `xyz-wireless-mouse`)  
     * **Original URL:** paste the full affiliate link.  
     * **Merchant:** select Lazada, Shopee, or Involve.  
   - Click **Save**.

3. **Use the slug in templates**  
   - In any page, use the template tag:  
     `{% affiliate_url 'xyz-wireless-mouse' %}`  
   - The tag will output `/out/xyz-wireless-mouse/`, which redirects through your tracking system.

4. **Verify**  
   - Visit `/out/xyz-wireless-mouse/` – you should be redirected to the affiliate URL.  
   - Check admin → Affiliate Clicks to see the logged click.