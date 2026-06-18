# Steps - Generating Involve Deep Links for Shopee Products

This guide explains how to obtain a unique Involve tracking link for each Shopee product, and how to add it to your Django affiliate system so the “View on Shopee” button works correctly.

---

## 1. Find the Shopee product page URL

Go to `shopee.ph` and search for the product.  
Copy the full URL from your browser’s address bar, e.g.:  
`https://shopee.ph/gencerda/40352579924`

---

## 2. Open the Involve Asia Deep Link Generator

- Log in to your Involve Asia publisher account.  
- In the left sidebar, go to **Tools → Deep Link Generator**.  

---

## 3. Generate the tracking link

- In the **Destination URL** field, paste the Shopee product URL from step 1.  
- Make sure your property **Humrine.com** is selected.  
- Click **Generate Link**.  

---

## 4. Copy the tracking link

A modal will appear showing your **Tracking Link**.  
It looks like `https://invl.me/clXXXXX` (a short Involve URL).  
Click **Copy** to save it to your clipboard.  

---

## 5. Add the link to your CSV file

Open your `links.csv` file.  
Each row should now have:

- `slug` – a unique identifier, e.g. `sacred-heart-shirt`  
- `title` – the product name  
- `original_url` – **paste the Involve tracking link from step 4**  
- `merchant` – `shopee`  
- `description` – product description  
- `image_url` – the Shopee image URL (right‑click the product image → Copy image address)  
- `price` – optional, the product price  

**Important:** Every product must have its own unique tracking link.  
Do not reuse the same `invl.me` link for different products.

Example row:

```csv
sacred-heart-shirt,Sacred Heart of Jesus Sublimation Shirt,https://invl.me/clUNIQUE1,shopee,"Sacred heart of Jesus inspired sublimation shirt adult",https://down-ph.img.susercontent.com/file/...,599
```

---

## 6. Import the CSV into Django

### Option A – Via Django admin (web upload)

- Go to `/admin/affiliate/trackedaffiliatelink/`  
- Click the **Import CSV** button (next to “Add”)  
- Choose your updated CSV file  
- Click **Upload and Preview**  
- Review the data, then click **Confirm and Import**

### Option B – Via management command

```bash
python manage.py import_affiliate_links affiliate/data/links.csv
```

---

## 7. Verify the link

Visit `/out/<slug>/` in your browser (e.g. `/out/sacred-heart-shirt/`).  
You should be redirected to the Shopee product page, and a click entry will appear in the admin.

---

## Done

Now every “View on Shopee” button on your deals page will correctly send users to the right product, with your affiliate tracking embedded.