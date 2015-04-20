'use strict';

const ActionTypes = require('../constants').ActionTypes;
const Dispatcher = require('../dispatcher');
const Store = require('./es6_store')

let _stories = []
let _filter = ""
let _products = []
let _loading = false
let _page = 0
let _pages = 1

class UserStoryTimelineStore extends Store {
  constructor() {
    super()

    this.dispatchToken = Dispatcher.register((action) => {
      switch(action.type) {
        case ActionTypes.USER_STORIES_RECEIVE:
          _stories = action.stories
          _products = action.products
          _loading = false
          _page = _page + 1
          _pages = action.pages
          this.emitChange()
          break

        case ActionTypes.USER_STORIES_REQUEST:
          _loading = true
          this.emitChange()
          break
      }
    })
  }

  getStories() {
    return _stories
  }

  getPage(){
    return _page
  }

  getPages(){
    return _pages
  }

  getProducts(){
    return _products
  }

  getFilter(){
    return _filter
  }

  getLoading() {
    return _loading
  }


}

module.exports = new UserStoryTimelineStore;
