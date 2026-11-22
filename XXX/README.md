# XXX Manager — سيد الدكان

Standalone Flutter manager app on branch `xxx-manager-app`, connected to the existing Sayed Al-Dukan Supabase project.

## Implemented in the current Flutter UI

- Email/password login using Supabase Auth.
- Checks the signed-in user against the `admins` table before allowing entry; unauthorized users are signed out.
- Manager dashboard with live counts for products, orders, customers, and reviews.
- Refresh dashboard data and sign out.
- Product list, add/edit product form, price, minimum order, description, ingredients, image URL, display ordering, active/hidden status, gallery upload to `product-images`, and delete.
- Order list, order details and item lines, address snapshot, status selector (new, confirmed, preparing, shipped, delivered, cancelled), and order event history/update.
- Customer profile list.
- Review list and removal.
- Editable `app_content` entries (title, body, image and publish toggle).
- Additional manager panels wired to tables in the additive schema: store settings, categories, pages, banners, coupons, customer messages/replies, broadcasts, admin notices and change log.
- Arabic interface and dark styling.

## Important limitations / setup status

- The extra `xxx_*` tables are described in `supabase/manager_schema.sql`; this schema is additive and is **not deployed automatically**. They must exist and have correct access policies before these panels can work.
- Broadcast panel currently stores drafts/records; it does not deliver push notifications by itself.
- Biometrics are listed as planned in the package dependencies but are not implemented in the current login flow.
- The app uses the Supabase publishable key only; never put a service-role key in a mobile app.
- The current build workflow produces a debug APK artifact, not a signed production release.

## Build

The GitHub Actions workflow `.github/workflows/build-xxx-apk.yml` builds the APK from branch `xxx-manager-app`.
