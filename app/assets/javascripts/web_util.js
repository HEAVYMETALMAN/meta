var Dispatcher = require('./dispatcher');

module.exports = {
  getAndDispatch(url, actionType) {
    $.ajax({
      type: "GET",
      url: url,
      dataType: 'json',
      success: (data) => {
        Dispatcher.dispatch(
          _.extend({type: actionType}, data)
        )
      }
    })
  },

  get(url, success) {
    $.ajax({
      type: "GET",
      url: url,
      dataType: 'json',
      success: success
    })
  },

  patch(url, data) {
    $.ajax({
      type: "PATCH",
      url: url,
      dataType: 'json',
      data: data
    })
  }
}
