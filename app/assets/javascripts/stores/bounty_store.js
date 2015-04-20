var ActionTypes = require('../constants').ActionTypes;
var Dispatcher = require('../dispatcher');
var Store = require('./es6_store');

var _dispatchToken
var _bounty = {}

class BountyStore extends Store {
  constructor() {
    super()

    _dispatchToken = Dispatcher.register((action) => {
      switch (action.type) {
        case ActionTypes.BOUNTY_RECEIVE:
          _bounty = action.bounty;
          this.emitChange();
          break;
        case ActionTypes.BOUNTY_WORK_SUBMITTED:
          _submitWork()
          this.emitChange()
          break
        case ActionTypes.BOUNTY_CLOSED:
          _closeBounty()
          this.emitChange()
          break
        case ActionTypes.BOUNTY_DESELECT_CURRENT:
          _bounty = {}
          this.emitChange()
          break
        case ActionTypes.BOUNTY_REOPENED:
          _reopenBounty()
          this.emitChange()
          break
      }
    })
  }

  getBounty() {
    return _bounty;
  }

  getState() {
    return _bounty.state
  }
}

module.exports = new BountyStore()

function _closeBounty() {
  _bounty.state = 'closed'
}

function _reopenBounty() {
  _bounty.state = 'open'
}

function _submitWork() {
  _bounty.state = 'reviewing'
}
