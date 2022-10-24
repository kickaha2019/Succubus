function child( parent, name) {
  const collection = document.body.children;
  for (let i = 0; i < collection.length; i++) {
    if (collection[i].name == name) {
      return collection[i];
    }
  }
}

function contract_all(parent) {
  const collection = parent.children;
  for (let i = 0; i < collection.length; i++) {
    child( collection[i], 'contract').style.display = 'none';
    child( collection[i], 'expand').style.display = 'inline';
    child( collection[i], 'menu').style.display = 'none';
  }
}

function contract(ev) {
  ev.preventDefault();
  const parent = ev.target.parentNode;
  child( parent, 'expand').style.display = 'inline';
  child( parent, 'menu').style.display = 'none';
}

function expand(ev) {
  ev.preventDefault();
  const parent = ev.target.parentNode;
  contract_all( parent.parentNode);
  child( parent, 'contract').style.display = 'inline';
  child( parent, 'menu').style.display = 'block';
}
