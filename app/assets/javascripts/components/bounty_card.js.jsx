'use strict'

const Icon = require('./ui/icon.js.jsx');
const Avatar = require('./ui/avatar.js.jsx');
const AppCoins = require('./app_coins.js.jsx');
var AppIcon = require('./app_icon.js.jsx')

const BountyCard = React.createClass({

  propTypes: {
    bounty: React.PropTypes.object.isRequired,
    showProduct: React.PropTypes.bool
  },

  render: function() {
    let bounty = this.props.bounty
    let coins = bounty.coins || bounty.earnable_coins
    let locker = null,
        meta = null,
        comments = null,
        hearts = null

    if (bounty.locker) {
      locker = <div className="right ml3">
        <Avatar user={bounty.locker} />
      </div>
    }

    if (bounty.comments_count > 0) {
      comments = <div className="left px1">
        <Icon icon="comment" /> {bounty.comments_count}
      </div>
    }

    if (bounty.hearts_count > 0) {
      hearts = <div className="left px1">
        <Icon icon="heart" /> {bounty.hearts_count}
      </div>
    }

    if (this.props.showProduct) {
      var productIcon = <div className="right px1">
        <AppIcon app={bounty.product} size={24} />
      </div>
    }
    else {
      var productIcon = <div />
    }

    return (
      <div className="clearfix">
        {locker}

        <div className="overflow-hidden">
          <div className="bold">
            {bounty.title}
          </div>
          <div className="clearfix mxn1 h6 gray-3" style={{lineHeight: '2rem'}}>
            <div className="left px1">
              <AppCoins n={coins} color="gray-3" />
            </div>
            {productIcon}
            {comments}
            {hearts}
          </div>
        </div>
      </div>
    )
  }
})

module.exports = window.BountyCard = BountyCard
