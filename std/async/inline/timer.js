/*----------------------------------------------------------------------------
   Copyright 2024, Koka-Community Authors

   Licensed under the MIT License ("The License"). You may not
   use this file except in compliance with the License. A copy of the License
   can be found in the LICENSE file at the root of this distribution.
----------------------------------------------------------------------------*/

function _init_timer(){
  return {};
}

function _start_timer(timer, ms, repeat, fcn){
  const rp = Number(repeat)
  const msx = Number(ms)
  if (rp != 0) {
    timer.id = setInterval(fcn, rp);
    timer.repeat = rp;
  } else {
    timer.id = setTimeout(fcn, msx);
  } 
}

function _stop_timer(timer){
  if (timer.id) {
    if (timer.repeat != 0) {
      clearInterval(timer.id);
    } else {
      clearTimeout(timer.id);
    }
    timer.id = null;
  }
}