
function maybeget(obj, key) {
  const _x = obj[key];
  if (_x === undefined || _x === null) {
    return $std_core_types.Nothing;
  } else {
    return $std_core_types.Just(_x);
  }
}