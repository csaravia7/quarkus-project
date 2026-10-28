const tbody = document.getElementById('products');
const errorEl = document.getElementById('error');
const noticeEl = document.getElementById('notice');
const dialog = document.getElementById('product-dialog');
const form = document.getElementById('product-form');
const idInput = document.getElementById('product-id');
const nameInput = document.getElementById('name');
const priceInput = document.getElementById('price');
const saveButton = document.getElementById('save-product');
const searchInput = document.getElementById('product-search');
const currency = new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' });
let products = [];

async function request(url, options = {}) {
  const response = await fetch(url, {
    ...options,
    headers: {
      Accept: 'application/json',
      ...(options.body ? { 'Content-Type': 'application/json' } : {}),
      ...options.headers,
    },
  });

  if (!response.ok) {
    let message = `Request failed (${response.status})`;
    try {
      const body = await response.json();
      message = body.message || body.error || message;
    } catch {
      // Keep the HTTP status when the server does not return JSON.
    }
    throw new Error(message);
  }

  return response.status === 204 ? null : response.json();
}

async function loadProducts() {
  errorEl.hidden = true;
  try {
    products = await request('/api/products');
    renderProducts();
    document.getElementById('product-count').textContent = products.length;
    document.getElementById('catalog-value').textContent = currency.format(
      products.reduce((total, product) => total + Number(product.price), 0),
    );
  } catch (error) {
    errorEl.textContent = error.message;
    errorEl.hidden = false;
    tbody.replaceChildren();
  }
}

function renderProducts() {
  const query = searchInput.value.trim().toLocaleLowerCase();
  const visibleProducts = products.filter((product) =>
    product.name.toLocaleLowerCase().includes(query) || String(product.id).includes(query),
  );

  if (visibleProducts.length === 0) {
    const row = document.createElement('tr');
    const cell = document.createElement('td');
    cell.colSpan = 4;
    cell.className = 'empty-state';
    cell.textContent = query ? 'No matching products' : 'No products in the catalog';
    row.appendChild(cell);
    tbody.replaceChildren(row);
    return;
  }

  tbody.replaceChildren(...visibleProducts.map(createRow));
}

function createRow(product) {
  const row = document.createElement('tr');
  row.append(
    createCell('ID', product.id),
    createCell('Product', product.name, 'product-name'),
    createCell('Price (USD)', currency.format(Number(product.price))),
  );

  const actions = document.createElement('td');
  actions.dataset.label = 'Actions';
  actions.className = 'actions-cell';

  const editButton = document.createElement('button');
  editButton.className = 'text-button';
  editButton.type = 'button';
  editButton.textContent = 'Edit';
  editButton.addEventListener('click', () => openEditor(product));

  const deleteButton = document.createElement('button');
  deleteButton.className = 'text-button text-button-danger';
  deleteButton.type = 'button';
  deleteButton.textContent = 'Delete';
  deleteButton.addEventListener('click', () => deleteProduct(product));

  actions.append(editButton, deleteButton);
  row.appendChild(actions);
  return row;
}

function createCell(label, value, className = '') {
  const cell = document.createElement('td');
  cell.dataset.label = label;
  cell.textContent = value;
  if (className) cell.className = className;
  return cell;
}

function openEditor(product = null) {
  form.reset();
  idInput.value = product?.id ?? '';
  nameInput.value = product?.name ?? '';
  priceInput.value = product?.price ?? '';
  document.getElementById('dialog-title').textContent = product ? 'Edit product' : 'Add product';
  saveButton.textContent = product ? 'Save changes' : 'Create product';
  errorEl.hidden = true;
  dialog.showModal();
  nameInput.focus();
}

async function deleteProduct(product) {
  if (!window.confirm(`Delete “${product.name}”?`)) return;

  try {
    await request(`/api/products/${product.id}`, { method: 'DELETE' });
    noticeEl.textContent = `${product.name} deleted`;
    noticeEl.hidden = false;
    await loadProducts();
  } catch (error) {
    errorEl.textContent = error.message;
    errorEl.hidden = false;
  }
}

form.addEventListener('submit', async (event) => {
  event.preventDefault();
  const id = idInput.value;
  const product = {
    name: nameInput.value.trim(),
    price: Number(priceInput.value),
  };

  saveButton.disabled = true;
  try {
    await request(id ? `/api/products/${id}` : '/api/products', {
      method: id ? 'PUT' : 'POST',
      body: JSON.stringify(product),
    });
    dialog.close();
    noticeEl.textContent = id ? `${product.name} updated` : `${product.name} added`;
    noticeEl.hidden = false;
    await loadProducts();
  } catch (error) {
    errorEl.textContent = error.message;
    errorEl.hidden = false;
  } finally {
    saveButton.disabled = false;
  }
});

document.getElementById('add-product').addEventListener('click', () => openEditor());
document.getElementById('close-dialog').addEventListener('click', () => dialog.close());
document.getElementById('cancel-dialog').addEventListener('click', () => dialog.close());
searchInput.addEventListener('input', renderProducts);

loadProducts();
