function child_display( parent, name, display) {
  const collection = parent.children;
  for (let i = 0; i < collection.length; i++) {
    console.log( collection[i].className);
    if (collection[i].className == name) {
      collection[i].style.display = display;
      return;
    }
  }
}

function contract_all(parent) {
  const collection = parent.children;
  for (let i = 0; i < collection.length; i++) {
    child_display( collection[i], 'contract', 'none');
    child_display( collection[i], 'expand', 'inline');
    child_display( collection[i], 'menu0', 'none');
    child_display( collection[i], 'menu1', 'none');
    child_display( collection[i], 'menu2', 'none');
  }
}

function contract(ev) {
  ev.preventDefault();
  const parent = ev.target.parentNode;
  contract_all( parent.parentNode);
  child_display( parent, 'expand', 'inline');
  child_display( parent, 'contract', 'none');
  child_display( parent, 'menu0', 'none');
  child_display( parent, 'menu1', 'none');
  child_display( parent, 'menu2', 'none');
}

function expand(ev) {
  ev.preventDefault();
  const parent = ev.target.parentNode;
  contract_all( parent.parentNode);
  child_display( parent, 'expand', 'none');
  child_display( parent, 'contract', 'inline');
  child_display( parent, 'menu0', 'block');
  child_display( parent, 'menu1', 'block');
  child_display( parent, 'menu2', 'block');
}
