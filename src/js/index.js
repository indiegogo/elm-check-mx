import Elm from '../elm/CheckMx';

(function() {
  var elmWorker = Elm.CheckMx.worker();
  // assist debug
  window.elmWorker = elmWorker;

  elmWorker.ports.checkEmailResponse.subscribe(function(ob) {
    console.log("response subscription called")
    console.log(JSON.stringify(ob))
  })

  elmWorker.ports.checkEmail.send("curtis@gnail.com")

}).call(this);
