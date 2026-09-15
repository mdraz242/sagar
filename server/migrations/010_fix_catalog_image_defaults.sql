with image_fixes(slug, name_pattern, image_url) as (
  values
    ('biscuit', '%biscuit%', 'products/parle-g.jpg'),
    ('biscuits', '%biscuit%', 'products/parle-g.jpg'),
    ('haircare', '%hair%', 'products/clinic-plus-sachet.jpg'),
    ('hair-care', '%hair%', 'products/clinic-plus-sachet.jpg'),
    ('personal', '%personal%', 'products/colgate.jpg'),
    ('home', '%home care%', 'products/surf-excel.jpg'),
    ('home-care', '%home care%', 'products/surf-excel.jpg'),
    ('atta', '%atta%', 'products/aashirvaad.jpg'),
    ('atta-dal', '%atta%', 'products/aashirvaad.jpg'),
    ('chips', '%chips%', 'products/lays.jpg'),
    ('snacks', '%snack%', 'products/lays.jpg'),
    ('instantfood', '%instant%', 'products/maggi.jpg')
)
update categories c
set image_url = f.image_url,
    updated_at = now()
from image_fixes f
where (lower(c.slug) = f.slug or lower(c.name_en) like f.name_pattern)
  and (
    c.image_url is null
    or trim(c.image_url) = ''
    or c.image_url in ('products/coke.png', 'products/coca-cola.jpg')
  );

update products
set image_url = 'products/parle-g.jpg',
    images_json = jsonb_build_array('products/parle-g.jpg'),
    updated_at = now()
where lower(name_en) like '%parle%'
  and (
    image_url is null
    or trim(image_url) = ''
    or image_url in ('products/coke.png', 'products/coca-cola.jpg')
  );

update products
set image_url = 'products/clinic-plus-sachet.jpg',
    images_json = jsonb_build_array('products/clinic-plus-sachet.jpg'),
    updated_at = now()
where lower(name_en) like '%clinic%'
  and (
    image_url is null
    or trim(image_url) = ''
    or image_url in ('products/coke.png', 'products/coca-cola.jpg')
  );

update products
set image_url = 'products/maggi.jpg',
    images_json = jsonb_build_array('products/maggi.jpg'),
    updated_at = now()
where lower(name_en) like '%maggi%'
  and (
    image_url is null
    or trim(image_url) = ''
    or image_url in ('products/coke.png', 'products/coca-cola.jpg')
  );

update products
set image_url = 'products/lays.jpg',
    images_json = jsonb_build_array('products/lays.jpg'),
    updated_at = now()
where lower(name_en) like '%lay%'
  and (
    image_url is null
    or trim(image_url) = ''
    or image_url in ('products/coke.png', 'products/coca-cola.jpg')
  );
