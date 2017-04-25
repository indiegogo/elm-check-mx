import Elm from '../elm/CheckMx';

class CheckMxImpl {
  constructor() {
    this.getElmWorker = function() {
      this.elmWorker = this.elmWorker || Elm.CheckMx.worker();
      // assist debug
      window.__elmWorker__ = this.elmWorker;
      return this.elmWorker;
    }

    this.setCallback = function(__callback) {
      const defaultCallback = function(ob) {
        console.log("___ default response subscription callback ___");
        console.log("email used for checking : "+ ob.email);
        console.log("hostname mx checked : "+ ob.hostname);
        console.log("hostname mx valid? : "+ ob.validMx);
        console.log("has possible replacement host suggestion : "+ ob.hasSuggestion);
        console.log("possible replacement host suggestion : "+ ob.suggestion);
      };

      if(typeof __callback === 'undefined'
         && typeof this.callback === 'undefined') {
        // base case - no callback - no user defined callback
        this.callback = defaultCallback; // use the default as there is no user defined callback
        this.getElmWorker().ports.checkEmailResponse.subscribe(this.callback);
        console.log("CheckMx::WARNING using defaultCallback")
      } else { // repeat using case
          if(typeof this.callback !== 'undefined') { // this.callback is set
            // is __callback unset?
            if (typeof __callback === 'undefined') {
                // leave this.callback alone
                // it's already set and __callback is not set
            } else {
              // we have a new callback and an old callback
              // remove the old callback and set the new one
              this.getElmWorker().ports.checkEmailResponse.unsubscribe(this.callback);
              this.callback  = __callback;
              this.getElmWorker().ports.checkEmailResponse.subscribe(this.callback);
            }
          } else {
            // we have a user defined callback
            // and have never set this.callback
            this.callback  = __callback;
            this.getElmWorker().ports.checkEmailResponse.subscribe(this.callback);
          }
        }
    };

    this.checkEmail = function(email) {
      if (this.callback) {
        this.getElmWorker().ports.checkEmail.send(email);
        
      } else {
        throw "CheckMX::ERROR No Callback configured";
      }
    }
  }
}

(function (global) {
  'use strict';


  // AMD support
  if (typeof define === 'function' && define.amd) {
    define(function () { return CheckMxImpl; });
    // CommonJS and Node.js module support.
  } else if (typeof exports !== 'undefined') {
    // Support Node.js specific `module.exports` (which can be a function)
    if (typeof module !== 'undefined' && module.exports) {
      exports = module.exports = CheckMxImpl;
    }
    // But always support CommonJS module 1.1.1 spec (`exports` cannot be a function)
    exports.CheckMx = CheckMxImpl;
  } else {
    global.CheckMx = CheckMxImpl;
  }
})(window);


