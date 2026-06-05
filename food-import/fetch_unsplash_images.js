// fetch_unsplash_resume.js
// ─────────────────────────────────────────────────────────
// รันต่อจากที่ค้างไว้ — ข้ามรายการที่มี imageUrl แล้ว
// วิธีใช้:
//
// รันซ้ำได้เรื่อยๆ จนครบ (ครั้งละ ~50 รายการ)
// ─────────────────────────────────────────────────────────

const fs   = require('fs');
const https = require('https');

const ACCESS_KEY = '2cQgkY5RJzegEdBtvV0gQgxv0EF7e8EPZcIEn8_IhaI'; // ← ใส่ key ของคุณ

if (ACCESS_KEY === 'YOUR_UNSPLASH_ACCESS_KEY') {
  console.error('❌ กรุณาใส่ Access Key ก่อน!');
  process.exit(1);
}

// โหลด foods_with_images.json ถ้ามี ไม่งั้นใช้ foods.json
const inputFile  = fs.existsSync('./foods_with_images.json')
  ? './foods_with_images.json'
  : './foods.json';

console.log('📂 อ่านจาก:', inputFile);
const foods = require(inputFile);

// นับรายการที่ยังไม่มีรูป
const pending = foods.filter(f => !f.imageUrl);
const done    = foods.filter(f =>  f.imageUrl);
console.log('✅ มีรูปแล้ว :', done.length,    'รายการ');
console.log('⏳ ยังไม่มีรูป:', pending.length, 'รายการ');

if (pending.length === 0) {
  console.log('\n🎉 ครบแล้ว! ไม่ต้องรันอีก');
  process.exit(0);
}

// ── query map ──────────────────────────────────────────────
function getQuery(name, category) {
  const n = name.toLowerCase();
  if (n.includes('ข้าวมันไก่'))         return 'hainanese chicken rice';
  if (n.includes('ผัดกะเพราไก่'))       return 'thai basil chicken';
  if (n.includes('ต้มยำไก่'))           return 'tom yum chicken soup';
  if (n.includes('ต้มข่าไก่'))          return 'thai coconut chicken soup';
  if (n.includes('ลาบ') && n.includes('ไก่')) return 'thai larb chicken';
  if (n.includes('ไก่ต้ม'))             return 'boiled chicken soup';
  if (n.includes('ไก่อบ'))              return 'roasted herb chicken';
  if (n.includes('ไก่ทอด'))             return 'fried chicken';
  if (n.includes('สเต็กไก่'))           return 'chicken steak';
  if (n.includes('อกไก่นึ่ง'))          return 'steamed chicken breast';
  if (n.includes('อกไก่ปั่น') || n.includes('อกไก่ย่าง')) return 'grilled chicken breast';
  if (n.includes('ยำไข่') && n.includes('ไก่')) return 'thai chicken egg salad';
  if (n.includes('ผัดผักรวม') && n.includes('ไก่')) return 'stir fry chicken vegetables';
  if (n.includes('ข้าวกล้อง') && n.includes('ไก่')) return 'brown rice grilled chicken';
  if (n.includes('ข้าวหน้าไก่'))        return 'chicken rice bowl';
  if (n.includes('ไก่'))                return 'thai chicken dish';
  if (n.includes('แซลมอน'))             return 'grilled salmon fillet';
  if (n.includes('ปลานึ่ง'))            return 'steamed fish thai';
  if (n.includes('ทูน่า'))              return 'tuna dish healthy';
  if (n.includes('ปลากะพง'))            return 'sea bass fish';
  if (n.includes('ปลาทอด'))             return 'fried fish thai';
  if (n.includes('ปลาดุก'))             return 'grilled catfish';
  if (n.includes('แกงส้มปลา'))          return 'thai sour curry fish';
  if (n.includes('ปลาหมึกย่าง'))        return 'grilled squid';
  if (n.includes('ปลาหมึก'))            return 'squid seafood';
  if (n.includes('ปลา'))                return 'thai fish dish';
  if (n.includes('กุ้งมังกร'))          return 'lobster butter garlic';
  if (n.includes('กุ้งลวก'))            return 'boiled shrimp';
  if (n.includes('กุ้งเผา'))            return 'grilled shrimp';
  if (n.includes('กุ้งผัดเนย'))         return 'butter garlic shrimp';
  if (n.includes('ชะอมกุ้ง'))           return 'thai sour curry shrimp';
  if (n.includes('แกงเลียง'))           return 'thai herb vegetable soup';
  if (n.includes('สุกี้'))              return 'thai suki hot pot';
  if (n.includes('กุ้ง'))               return 'thai shrimp dish';
  if (n.includes('หมูสามชั้น'))         return 'pork belly crispy';
  if (n.includes('หมูกระทะ'))           return 'thai bbq pork';
  if (n.includes('คอหมู'))              return 'grilled pork neck';
  if (n.includes('หมูสันใน'))           return 'pork tenderloin';
  if (n.includes('หมูอบ'))              return 'baked pork herb';
  if (n.includes('ลาบหมู'))             return 'thai larb pork';
  if (n.includes('หมูผัด'))             return 'stir fry pork thai';
  if (n.includes('หมูย่าง'))            return 'grilled pork thai';
  if (n.includes('หมู'))                return 'thai pork dish';
  if (n.includes('สเต็กเนื้อ') || n.includes('เนื้อสันนอก')) return 'beef steak grilled';
  if (n.includes('ยำเนื้อ'))            return 'thai beef salad';
  if (n.includes('เนื้อผัด'))           return 'stir fry beef';
  if (n.includes('เนื้อ'))              return 'beef dish thai';
  if (n.includes('เป็ด'))               return 'roasted duck';
  if (n.includes('ไข่ขาวต้ม'))          return 'egg whites boiled';
  if (n.includes('ไข่ต้ม'))             return 'hard boiled eggs';
  if (n.includes('ไข่ดาว') || n.includes('ไข่คน')) return 'fried eggs';
  if (n.includes('ไข่เจียว'))           return 'thai omelette';
  if (n.includes('ไข่ออมเล็ต'))         return 'omelette egg';
  if (n.includes('ไข่พะโล้') || n.includes('ไข่ลูกเขย')) return 'thai braised eggs';
  if (n.includes('ไข่'))                return 'egg dish thai';
  if (n.includes('ซุปมิโซะ'))           return 'miso soup tofu';
  if (n.includes('เต้าหู้ทอด'))         return 'fried tofu';
  if (n.includes('เต้าหู้'))            return 'tofu dish healthy';
  if (n.includes('ข้าวผัด'))            return 'fried rice thai';
  if (n.includes('ข้าวกล้อง'))          return 'brown rice healthy';
  if (n.includes('ข้าวคลุกกะปิ'))       return 'thai shrimp paste rice';
  if (n.includes('ข้าวหมูแดง'))         return 'red pork rice';
  if (n.includes('ข้าวต้ม'))            return 'rice porridge congee';
  if (n.includes('ข้าว'))               return 'thai rice dish';
  if (n.includes('ผัดไทย'))             return 'pad thai noodles';
  if (n.includes('ก๋วยเตี๋ยวต้มยำ'))   return 'tom yum noodle soup';
  if (n.includes('ก๋วยเตี๋ยวผัดซีอิ๊ว')) return 'pad see ew noodles';
  if (n.includes('ก๋วยเตี๋ยว'))         return 'thai noodle soup';
  if (n.includes('บะหมี่'))             return 'egg noodle soup';
  if (n.includes('สปาเกตตี'))           return 'spaghetti seafood';
  if (n.includes('มักกะโรนี'))          return 'macaroni stir fry';
  if (n.includes('แกงเขียวหวาน') && n.includes('ไก่')) return 'thai green curry chicken';
  if (n.includes('แกงเขียวหวาน'))       return 'thai green curry tofu';
  if (n.includes('แกงมัสมั่น'))         return 'massaman curry';
  if (n.includes('แกงส้ม'))             return 'thai sour curry';
  if (n.includes('แกงจืด'))             return 'thai clear soup';
  if (n.includes('แกง'))                return 'thai curry';
  if (n.includes('ต้มยำทะเล'))          return 'tom yum seafood';
  if (n.includes('ต้มยำกุ้ง'))          return 'tom yum goong';
  if (n.includes('ต้มยำ'))              return 'tom yum soup';
  if (n.includes('ต้มข่า'))             return 'tom kha soup';
  if (n.includes('ต้มจืด'))             return 'clear soup thai';
  if (n.includes('ส้มตำ'))              return 'papaya salad som tum';
  if (n.includes('ยำวุ้นเส้น'))         return 'glass noodle salad thai';
  if (n.includes('ยำสาหร่าย'))          return 'seaweed salad';
  if (n.includes('สลัดผัก'))            return 'fresh green salad';
  if (n.includes('สลัดโรล'))            return 'fresh spring roll';
  if (n.includes('ลาบเห็ด'))            return 'mushroom larb salad';
  if (n.includes('ยำเต้าหู้'))          return 'tofu salad thai';
  if (n.includes('ผัดผักบุ้ง'))         return 'stir fry morning glory';
  if (n.includes('ผัดถั่วงอก'))         return 'bean sprouts stir fry';
  if (n.includes('เห็ดผัด'))            return 'mushroom stir fry';
  if (n.includes('ต้มยำเห็ด'))          return 'mushroom soup thai';
  if (n.includes('ผัดกะเพรา'))          return 'thai basil stir fry';
  if (n.includes('ผัดคะน้า'))           return 'kale stir fry';
  if (n.includes('ซุปหน่อไม้'))         return 'bamboo shoot soup';
  switch (category) {
    case 'Low Carb':     return 'low carb healthy meal';
    case 'Balanced':     return 'balanced thai meal';
    case 'Vegetarian':   return 'vegetarian thai food';
    case 'High Protein': return 'high protein meal';
    case 'Keto':         return 'keto meal low carb';
    default:             return 'thai food';
  }
}

function fetchJson(url) {
  return new Promise((resolve, reject) => {
    https.get(url, { headers: { 'Authorization': 'Client-ID ' + ACCESS_KEY } }, (res) => {
      // ตรวจ rate limit header
      const remaining = res.headers['x-ratelimit-remaining'];
      if (remaining !== undefined) {
        process.stdout.write(' [remaining: ' + remaining + ']');
      }
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        if (res.statusCode === 403 || data.startsWith('Rate Limit')) {
          reject(new Error('RATE_LIMIT'));
          return;
        }
        try { resolve(JSON.parse(data)); }
        catch (e) { reject(new Error('RATE_LIMIT')); }
      });
    }).on('error', reject);
  });
}

function sleep(ms) {
  return new Promise(r => setTimeout(r, ms));
}

async function main() {
  // สร้าง map ของรายการที่มีรูปแล้ว
  const imageMap = {};
  foods.forEach(f => { if (f.imageUrl) imageMap[f.name] = f.imageUrl; });

  const results = [...foods]; // copy ทั้งหมด
  let fetched = 0;
  let rateLimited = false;

  for (let i = 0; i < results.length; i++) {
    const food = results[i];

    // ข้ามรายการที่มีรูปแล้ว
    if (food.imageUrl) continue;

    if (rateLimited) {
      // หยุดแล้วบันทึก ให้รันใหม่อีกชั่วโมง
      break;
    }

    const query = getQuery(food.name, food.category);
    process.stdout.write('[' + (i+1) + '/125] ' + food.name + '...');

    try {
      const url = 'https://api.unsplash.com/photos/random?query='
        + encodeURIComponent(query)
        + '&orientation=landscape&content_filter=high';

      const data = await fetchJson(url);
      results[i] = Object.assign({}, food, { imageUrl: data.urls.small });
      fetched++;
      console.log(' ✅');

    } catch (err) {
      if (err.message === 'RATE_LIMIT') {
        console.log(' ❌ Rate limit ถึงแล้ว หยุดชั่วคราว');
        rateLimited = true;
      } else {
        console.log(' ❌ ' + err.message);
      }
    }

    await sleep(1500);
  }

  // บันทึก progress ทุกครั้ง
  fs.writeFileSync('./foods_with_images.json', JSON.stringify(results, null, 2));

  const totalDone    = results.filter(f => f.imageUrl).length;
  const totalPending = results.filter(f => !f.imageUrl).length;

  console.log('\n══════════════════════════════════');
  console.log('รอบนี้ fetch ได้ : ' + fetched + ' รายการ');
  console.log('มีรูปแล้ว        : ' + totalDone + ' / 125 รายการ');
  console.log('ยังไม่มีรูป      : ' + totalPending + ' รายการ');
  console.log('บันทึกแล้ว       : foods_with_images.json');

  if (totalPending > 0) {
    console.log('\n⏰ รอ 1 ชั่วโมง แล้วรันใหม่:');
    console.log('   node fetch_unsplash_resume.js');
  } else {
    console.log('\n🎉 ครบ 125 รายการแล้ว!');
    console.log('ขั้นตอนต่อไป:');
    console.log('  1. copy foods_with_images.json → foods.json');
    console.log('  2. node import_foods.js');
  }
}

main().catch(console.error);