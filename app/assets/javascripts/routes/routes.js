'use strict';

const DashboardHandlers = require('./dashboard_handlers');
const IdeasHandlers = require('./ideas_handlers');
const ProductsHandlers = require('./products_handlers');

module.exports = [
  ['/dashboard', require('../components/dashboard/dashboard_index.js.jsx'), DashboardHandlers.showDashboard],
  ['/dashboard/:filter', require('../components/dashboard/dashboard_index.js.jsx'), DashboardHandlers.showDashboard],
  ['/ideas', require('../components/ideas/ideas_index.js.jsx'), IdeasHandlers.showIdeas],
  ['/ideas/new', require('../components/ideas/ideas_new.js.jsx'), IdeasHandlers.showCreateIdea],
  ['/ideas/:id', require('../components/ideas/idea_show.js.jsx'), IdeasHandlers.showIdea],
  ['/ideas/:id/admin', require('../components/ideas/idea_admin.js.jsx'), IdeasHandlers.showIdeaAdmin],
  ['/ideas/:id/edit', require('../components/ideas/idea_edit.js.jsx'), IdeasHandlers.showEditIdea],
  ['/ideas/:id/start-conversation', require('../components/ideas/idea_start_conversation.js.jsx'), IdeasHandlers.showStartConversation],
  ['/:id', require('../components/products/product_show.js.jsx'), ProductsHandlers.showProduct],
  ['/:product_id/activity', require('../components/products/product_activity.js.jsx')],
  ['/:product_id/metrics', require('../components/products/metrics_index.js.jsx'), ProductsHandlers.showProductMetrics],
  ['/:product_id/trust', require('../components/products/product_trust.js.jsx'), ProductsHandlers.showProductTrust],
  ['/:product_id/metrics/snippet', require('../components/products/metrics_snippet.js.jsx'), ProductsHandlers.showProductMetrics],
  ['/:product_id/partners', require('../components/products/product_partners.js.jsx'), ProductsHandlers.showProductPartners],

  ['/:product_id/bounties', require('../components/products/product_bounties.js.jsx'), ProductsHandlers.showProductBounties],
  ['/:product_id/bounties/:id', require('../components/products/product_bounty.js.jsx'), ProductsHandlers.showProductBounty],
];
