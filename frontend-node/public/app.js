const tbody = document.getElementById('products');
const errorEl = document.getElementById('error');

async function request(url, options = {}) {
  const res = await fetch(url, { headers: { 'Content-Type': 'application/json' }, ...options });
  if (!res.ok) throw new Error(`Error ${res.status}`);
  return res.status === 204 ? null : res.json();
}

async function load() {
  try {
    errorEl.textContent = '';
    const products = await request('/api/products');
    tbody.replaceChildren(...products.map(row));
  } catch (e) {
    errorEl.textContent = e.message;
  }
}

function row(p) {
  const tr = document.createElement('tr');
  for (const value of [p.id, p.name, p.price.toFixed(2)]) {
    const td = document.createElement('td');
    td.textContent = value;
    tr.appendChild(td);
  }
  const btn = document.createElement('button');
  btn.textContent = 'Eliminar';
  btn.onclick = async () => {
    await request(`/api/products/${p.id}`, { method: 'DELETE' });
    load();
  };
  const td = document.createElement('td');
  td.appendChild(btn);
  tr.appendChild(td);
  return tr;
}

document.getElementById('product-form').addEventListener('submit', async (e) => {
  e.preventDefault();
  const name = document.getElementById('name').value;
  const price = parseFloat(document.getElementById('price').value);
  try {
    await request('/api/products', { method: 'POST', body: JSON.stringify({ name, price }) });
    e.target.reset();
    load();
  } catch (err) {
    errorEl.textContent = err.message;
  }
});

load();
