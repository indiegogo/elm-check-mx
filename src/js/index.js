import Elm from '../elm/CheckMx';

(function() {
  var elmWorker = Elm.CheckMx.worker();
  // asist debug
  window.elmWorker = elmWorker;

  elmWorker.ports.check_email_response.subscribe(function(ob) {
    console.log("response subscription called")
    console.log(JSON.stringify(ob))
  })

  elmWorker.ports.check_email.send("curtis@gnail.com")

}).call(this);
