-- Jumlah Pesanan, Penjualan, dan AOV untuk "Mini Projector" di Amerika Utara Per Kuartal
SELECT
  EXTRACT(YEAR FROM PURCHASE_TS) AS purchase_year,
  EXTRACT(QUARTER FROM PURCHASE_TS) AS purchase_quarter,
  COUNT(DISTINCT ORDER_ID) AS order_count,
  ROUND(SUM(USD_PRICE)) AS total_sales,
  ROUND(AVG(USD_PRICE)) AS aov
FROM orders
WHERE
  PRODUCT_NAME LIKE '%Mini Projector%'
  AND COUNTRY_CODE IN ('US', 'CA', 'MX') -- Amerika Utara
GROUP BY 
  purchase_year,
  purchase_quarter
ORDER BY 
  purchase_year,
  purchase_quarter;

-- Pesanan Bulanan Mini Projector dalam USD (2019-2020)
SELECT
  DATE_FORMAT(PURCHASE_TS, '%Y-%m') AS purchase_month,
  COUNT(DISTINCT ORDER_ID) AS order_count
FROM orders
WHERE
  PRODUCT_NAME LIKE '%Mini Projector%'
  AND CURRENCY = 'USD'
  AND EXTRACT(YEAR FROM PURCHASE_TS) IN (2019, 2020)
GROUP BY purchase_month
ORDER BY purchase_month;

-- ID dan Nama Produk Unik untuk Produk Full HD Webcam dan Bluetooth Speaker
SELECT DISTINCT 
  PRODUCT_ID, 
  PRODUCT_NAME
FROM orders
WHERE 
  PRODUCT_NAME LIKE '%Full HD Webcam%'
  OR PRODUCT_NAME LIKE '%Bluetooth Speaker%'
ORDER BY PRODUCT_NAME;

-- Waktu Pengiriman Pesanan di Tahun 2020
SELECT
  EXTRACT(MONTH FROM PURCHASE_TS) AS purchase_month,
  EXTRACT(MONTH FROM SHIP_TS) AS ship_month,
  DATEDIFF(SHIP_TS, PURCHASE_TS) AS time_to_ship_days,
  PRODUCT_NAME
FROM orders
WHERE EXTRACT(YEAR FROM PURCHASE_TS) = 2020;

-- Rata-rata Waktu Pembelian untuk Pelanggan Loyalty vs Non-Loyalty
SELECT
  LOYALTY_PROGRAM,
  ROUND(AVG(DATEDIFF(PURCHASE_TS, CREATED_ON))) AS avg_time_to_purchase_days,
  COUNT(USER_ID) AS customer_count
FROM orders
GROUP BY LOYALTY_PROGRAM;

-- Nilai Rata-rata Pesanan (AOV) untuk Wireless Charger dan Network Switch
SELECT
  EXTRACT(YEAR FROM PURCHASE_TS) AS year,
  ROUND(AVG(USD_PRICE), 2) AS AOV,
  COUNT(ORDER_ID) AS total_orders
FROM orders
WHERE PRODUCT_NAME LIKE '%Wireless Charger%'
  OR PRODUCT_NAME LIKE '%Network Switch%'
GROUP BY year
ORDER BY year;

-- Jumlah Pelanggan Email/Mobile dan Affiliate/Desktop
SELECT
  COUNT(CASE 
          WHEN MARKETING_CHANNEL = 'email' AND ACCOUNT_CREATION_METHOD = 'mobile' 
          THEN USER_ID 
        END) AS email_mobile_count,
  COUNT(CASE 
          WHEN MARKETING_CHANNEL = 'affiliate' AND ACCOUNT_CREATION_METHOD = 'desktop' 
          THEN USER_ID 
        END) AS affiliate_desktop_count,
  COUNT(USER_ID) AS total_count
FROM orders;

-- Total Pesanan Per Tahun untuk Setiap Produk
SELECT
  EXTRACT(YEAR FROM PURCHASE_TS) AS purchase_year,
  EXTRACT(MONTH FROM PURCHASE_TS) AS purchase_month,
  TRIM(PRODUCT_NAME) AS product_name_clean,
  COUNT(ORDER_ID) AS total_orders
FROM orders
GROUP BY purchase_year, purchase_month, product_name_clean
ORDER BY purchase_month, product_name_clean, purchase_year;

-- Wilayah dengan Rata-rata Waktu Pengiriman Tertinggi
SELECT
  COUNTRY_CODE AS region,
  ROUND(AVG(DATEDIFF(DELIVERY_TS, PURCHASE_TS)), 2) AS avg_days_to_deliver
FROM orders
WHERE 
  (EXTRACT(YEAR FROM PURCHASE_TS) = 2022 AND PURCHASE_PLATFORM = 'website')
  OR PURCHASE_PLATFORM = 'mobile'
GROUP BY region
ORDER BY avg_days_to_deliver DESC;

-- Produk Paling Populer Per Wilayah
WITH region_sales AS (
  SELECT
    COUNTRY_CODE AS region,
    PRODUCT_NAME,
    COUNT(ORDER_ID) AS order_count
  FROM orders
  GROUP BY region, PRODUCT_NAME
)
SELECT region, PRODUCT_NAME, order_count
FROM region_sales
WHERE order_count = (
  SELECT MAX(order_count)
  FROM region_sales rs
  WHERE rs.region = region_sales.region
)
ORDER BY order_count DESC;

-- Rata-rata Total Penjualan (2019-2022)
WITH yearly_sales AS (
  SELECT 
    EXTRACT(YEAR FROM PURCHASE_TS) AS year,
    SUM(USD_PRICE) AS total_sales
  FROM orders
  WHERE EXTRACT(YEAR FROM PURCHASE_TS) BETWEEN 2019 AND 2022
  GROUP BY year
)
SELECT 
  ROUND(AVG(total_sales), 2) AS avg_sales_across_years
FROM yearly_sales;

-- Persentase pelanggan yang melakukan lebih dari satu pembelian dalam setahun, dikelompokkan berdasarkan tahun
WITH customer_orders AS (
  SELECT
    USER_ID AS customer_id,
    EXTRACT(YEAR FROM PURCHASE_TS) AS purchase_year,
    COUNT(ORDER_ID) AS order_count
  FROM orders
  GROUP BY USER_ID, EXTRACT(YEAR FROM PURCHASE_TS)
)
SELECT
  purchase_year,
  COUNT(DISTINCT customer_id) AS unique_customers,
  COUNT(CASE WHEN order_count > 1 THEN customer_id END) AS repeat_customers,
  ROUND(
    COUNT(CASE WHEN order_count > 1 THEN customer_id END) * 100.0 / COUNT(DISTINCT customer_id), 2
  ) AS repeat_rate
FROM customer_orders
WHERE purchase_year IS NOT NULL
GROUP BY purchase_year
ORDER BY purchase_year;

-- Total pelanggan dan total pesanan per wilayah
SELECT
  COUNTRY_CODE AS region,
  COUNT(DISTINCT USER_ID) AS customer_count,
  COUNT(DISTINCT ORDER_ID) AS order_count
FROM orders
GROUP BY COUNTRY_CODE
ORDER BY COUNTRY_CODE;

-- Rata-rata waktu pengiriman untuk setiap platform pembelian
SELECT
  PURCHASE_PLATFORM,
  ROUND(AVG(DATE_PART('day', DELIVERY_TS - PURCHASE_TS)), 2) AS avg_time_to_deliver
FROM orders
WHERE DELIVERY_TS IS NOT NULL
GROUP BY PURCHASE_PLATFORM;

-- Dua wilayah teratas untuk penjualan Full HD Webcam pada tahun 2020
SELECT
  COUNTRY_CODE AS region,
  ROUND(SUM(USD_PRICE), 2) AS webcam_sales
FROM orders
WHERE PRODUCT_NAME LIKE '%Full HD Webcam%'
  AND EXTRACT(YEAR FROM PURCHASE_TS) = 2020
GROUP BY COUNTRY_CODE
ORDER BY webcam_sales DESC
LIMIT 2;

-- Tiga pelanggan teratas berdasarkan jumlah pesanan untuk setiap platform pembelian
WITH customer_purchases AS (
  SELECT
    PURCHASE_PLATFORM,
    USER_ID AS customer_id,
    COUNT(ORDER_ID) AS order_count
  FROM orders
  GROUP BY PURCHASE_PLATFORM, USER_ID
)
SELECT
  PURCHASE_PLATFORM,
  customer_id,
  order_count,
  ROW_NUMBER() OVER (PARTITION BY PURCHASE_PLATFORM ORDER BY order_count DESC) AS ranking
FROM customer_purchases
WHERE ROW_NUMBER() OVER (PARTITION BY PURCHASE_PLATFORM ORDER BY order_count DESC) <= 3;

-- Merek yang paling banyak dibeli di wilayah APAC
SELECT
  CASE 
    WHEN PRODUCT_NAME LIKE '%Mini Projector%' THEN 'Mini Projector'
    WHEN PRODUCT_NAME LIKE '%Fitness Smartwatch%' THEN 'Fitness Smartwatch'
    WHEN PRODUCT_NAME LIKE '%Dash Cam%' THEN 'Dash Cam'
    ELSE 'Unknown'
  END AS brand,
  COUNT(ORDER_ID) AS order_count
FROM orders
WHERE COUNTRY_CODE IN ('CN', 'JP', 'KR', 'AU', 'IN') -- Contoh kode negara APAC
GROUP BY brand
ORDER BY order_count DESC
LIMIT 1;

-- Lima pelanggan teratas yang membeli produk All-in-One Printer berdasarkan AOV
WITH printer_customers AS (
  SELECT
    USER_ID AS customer_id,
    AVG(USD_PRICE) AS aov
  FROM orders
  WHERE PRODUCT_NAME LIKE '%All-in-One Printer%'
  GROUP BY USER_ID
)
SELECT
  customer_id,
  aov
FROM printer_customers
ORDER BY aov DESC
LIMIT 5;

-- Dua saluran pemasaran teratas berdasarkan AOV dalam setiap platform pembelian
WITH marketing_sales AS (
  SELECT
    PURCHASE_PLATFORM,
    MARKETING_CHANNEL,
    ROUND(AVG(USD_PRICE), 2) AS aov
  FROM orders
  GROUP BY PURCHASE_PLATFORM, MARKETING_CHANNEL
)
SELECT
  PURCHASE_PLATFORM,
  MARKETING_CHANNEL,
  aov
FROM (
  SELECT
    PURCHASE_PLATFORM,
    MARKETING_CHANNEL,
    aov,
    ROW_NUMBER() OVER (PARTITION BY PURCHASE_PLATFORM ORDER BY aov DESC) AS ranking
  FROM marketing_sales
) ranked_sales
WHERE ranking <= 2
ORDER BY PURCHASE_PLATFORM, aov DESC;
