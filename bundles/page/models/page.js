
// import local dependencies
const Model = require('model');

/**
 * create page class
 */
class Page extends Model {
  /**
   * construct page model
   *
   * @param attrs
   * @param options
   */
  constructor(...args) {
    // run super
    super(...args);

    // bind methods
    this.sanitise = this.sanitise.bind(this);
  }

  /**
   * sanitises bot
   *
   * @return {Object}
   */
  async sanitise(req) {
    // return sanitised bot
    return {
      id        : this.get('_id') ? this.get('_id').toString() : null,
      type      : this.get('type'),
      slug      : this.get('slug') || '',
      title     : this.get('title'),
      layout    : this.get('layout') || 'main',
      placement : await this.get('placement') ? await (await this.get('placement')).sanitise(req) : null,
    };
  }
}

/**
 * export page class
 *
 * @type {page}
 */
module.exports = Page;
