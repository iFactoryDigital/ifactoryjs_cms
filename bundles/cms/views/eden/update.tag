<eden-update>
  <div ref="placement" class="eden-blocks" if={ !this.placing }>
    <div each={ row, x in this.rows } data-row={ x } class="row eden-blocks-row mb-3 row-eq-height">
      <div each={ block, i in getBlocks(x) } data-block={ block.uuid } if={ getBlockData(block) } class={ getBlockData(block).class || 'col' } data-is="block-{ getBlockData(block).tag }" data={ getBlockData(block) } block={ block } on-save={ this.onSaveBlock } on-remove={ onRemoveBlock } on-refresh={ this.onRefreshBlock } />
    </div>
  </div>
  <block-modal blocks={ opts.blocks } add-block={ onAddBlock } />

  <script>
    // do mixins
    this.mixin('model');

    // set update
    this.rows      = [1, 2, 3, 4, 5, 6, 7, 8];
    this.type      = opts.type;
    this.blocks    = (opts.placement || {}).render || [];
    this.loading   = {};
    this.updating  = {};
    this.placement = opts.placement ? this.model('placement', opts.placement) : this.model('placement', {});

    /**
     * gets blocks
     *
     * @param  {Integer} i
     *
     * @return {*}
     */
    getBlocks (i) {
      // check blocks
      if (!this.placement.get('blocks')) return [];
      if (!this.placement.get('placements')) return [];

      // check blocks
      let row = [];

      // get placements
      let blocks = this.placement.get('placements')[i];

      // check blocks
      if (!blocks) return [];

      // return blocks
      return blocks.map((block) => {
        // return found
        return this.placement.get('blocks').find((b) => b.uuid === block);
      }).filter((item) => item);
    }

    /**
     * get block data
     *
     * @param  {Object} block
     *
     * @return {*}
     */
    getBlockData (block) {
      // get found
      let found = this.blocks.find((b) => b.uuid === block.uuid);

      // gets data for block
      if (!found) return null;

      // return found
      return found;
    }

    /**
     * on refresh block
     *
     * @param  {Event}  e
     * @param  {Object} block
     */
    async onSaveBlock (block, data, preventUpdate) {
      // prevent update check
      if (!preventUpdate) {
        // set loading
        block.saving = true;

        // update view
        this.update();
      }

      // log data
      let res = await fetch('/placement/' + this.placement.get('id') + '/block/save', {
        'body' : JSON.stringify({
          'data'  : data,
          'block' : block
        }),
        'method'  : 'post',
        'headers' : {
          'Content-Type' : 'application/json'
        },
        'credentials' : 'same-origin'
      });

      // load data
      let result = await res.json();

      // set logic
      for (let key in result.result) {
        // clone to placement
        data[key] = result.result[key];
        
        // set in placement
        opts.placement[data] = result.result[key];
      }

      // check prevent update
      if (!preventUpdate) {
        // set loading
        delete block.saving;

        // update view
        this.update();
      }
    }

    /**
     * on refresh block
     *
     * @param  {Event}  e
     * @param  {Object} block
     */
    async onRefreshBlock (block, data) {
      // set loading
      block.refreshing = true;

      // update view
      this.update();

      // log data
      let res = await fetch('/placement/' + this.placement.get('id') + '/block/save', {
        'body' : JSON.stringify({
          'data'   : data,
          'block' : block
        }),
        'method'  : 'post',
        'headers' : {
          'Content-Type' : 'application/json'
        },
        'credentials' : 'same-origin'
      });

      // load data
      let result = await res.json();

      // set logic
      for (let key in result.result) {
        // clone to placement
        data[key] = result.result[key];
      }

      // set loading
      delete block.refreshing;

      // update view
      this.update();
    }

    /**
     * on refresh block
     *
     * @param  {Event}  e
     * @param  {Object} block
     */
    async onRemoveBlock (block, data) {
      // set loading
      block.removing = true;

      // update view
      this.update();

      // log data
      let res = await fetch('/placement/' + this.placement.get('id') + '/block/remove', {
        'body' : JSON.stringify({
          'data'   : data,
          'block' : block
        }),
        'method'  : 'post',
        'headers' : {
          'Content-Type' : 'application/json'
        },
        'credentials' : 'same-origin'
      });

      // load data
      let result = await res.json();

      // remove from everywhere
      this.placement.set('blocks', this.placement.get('blocks').filter((w) => {
        // check found in row
        return block.uuid !== w.uuid;
      }));

      // set placements
      this.placement.set('placements', this.placement.get('placements').map((row) => {
        // filter row
        return row.filter((id) => id !== block.uuid);
      }));

      // save placement
      await this.savePlacement(this.placement);

      // set loading
      delete block.removing;

      // update view
      this.update();
    }

    /**
     * adds block by type
     *
     * @param  {String} type
     *
     * @return {*}
     */
    async onAddBlock (type) {
      // get uuid
      const uuid = require('uuid');

      // add block to first row
      if (!this.placement.get('blocks')) this.placement.set('blocks', []);
      if (!this.placement.get('placements')) this.placement.set('placements', []);

      // get placements/blocks
      let blocks     = this.placement.get('blocks')    || [];
      let placements = this.placement.get('placements') || [];

      // check placements
      if (!placements.length) placements.push([]);

      // create block
      let block = {
        'uuid' : uuid(),
        'type' : type
      };

      // push to blocks
      blocks.push(block);
      placements[0].unshift(block.uuid);

      // set
      this.placement.set('blocks',     blocks);
      this.placement.set('placements', placements);

      // save placement
      await this.savePlacement(this.placement);
      await this.loadBlocks(this.placement);
    }

    /**
     * saves placement
     *
     * @param  {Object}  placement
     *
     * @return {Promise}
     */
    async savePlacement (placement) {
      // set loading
      this.loading.save = true;

      // update view
      this.update();

      // check type
      if (!placement.type) placement.set('type', opts.type);

      // log data
      let res = await fetch('/placement/' + (placement.get('id') ? placement.get('id') + '/update' : 'create'), {
        'body'    : JSON.stringify(placement.get()),
        'method'  : 'post',
        'headers' : {
          'Content-Type' : 'application/json'
        },
        'credentials' : 'same-origin'
      });

      // load data
      let data = await res.json();

      // set logic
      for (let key in data.result) {
        // clone to placement
        placement.set(key, data.result[key]);
        
        // set in opts
        if (data.result[key]) opts.placement[key] = data.result[key];
      }

      // on save
      if (opts.onSave) opts.onSave(placement);

      // set loading
      this.loading.save = false;

      // update view
      this.update();
    }

    /**
     * saves placements
     *
     * @return {Promise}
     */
    async savePlacements () {
      // set placements
      let placements = [];

      // each row
      jQuery('> .row', this.refs.placement).each((i, item) => {
        // get row
        let row = [];

        // get each item in row
        jQuery('[data-block]', item).each((x, block) => {
          // push to row
          row.push(jQuery(block).attr('data-block'));
        });

        // push row to placements
        placements.push(row);
      });

      // set loading
      this.placing = true;
      this.loading.placements = true;

      // update view
      this.update();

      // filter blocks
      this.placement.set('blocks', this.placement.get('blocks').filter((block) => {
        // check found in row
        return placements.find((row) => {
          // return id === block id
          return row.find((id) => id === block.uuid);
        })
      }));

      // set placements
      this.placement.set('placements', placements);

      // set placing
      this.placing = false;

      // update view
      this.update();

      // init dragula again
      this.initDragula();

      // save
      await this.savePlacement(this.placement);

      // set loading
      this.loading.placements = false;

      // update view
      this.update();
    }

    /**
     * loads placement blocks
     *
     * @param  {Model} placement
     *
     * @return {Promise}
     */
    async loadBlocks (placement) {
      // set loading
      this.loading.blocks = true;

      // update view
      this.update();

      // check type
      if (!placement.type) placement.set('type', opts.type);

      // log data
      let res = await fetch('/placement/' + placement.get('id') + '/view', {
        'method'  : 'get',
        'headers' : {
          'Content-Type' : 'application/json'
        },
        'credentials' : 'same-origin'
      });

      // load data
      let data = await res.json();

      // set blocks
      this.blocks = data.result;

      // set loading
      this.loading.blocks = false;

      // update view
      this.update();
    }

    /**
     * init dragula
     */
    initDragula () {
      // require dragula
      const dragula = require('dragula');

      // do dragula
      this.dragula = dragula(jQuery('.row.eden-blocks-row', this.refs.placement).toArray(), {
        'moves' : (el, container, handle) => {
          return jQuery(handle).closest('.card-header').length;
        }
      }).on('drop', (el, target, source, sibling) => {
        // save order
        this.savePlacements();
      }).on('drag', () => {
        // add is dragging
        jQuery(this.refs.placement).addClass('is-dragging');
      }).on('dragend', () => {
        // remove is dragging
        jQuery(this.refs.placement).removeClass('is-dragging');
      });
    }

    /**
     * on update
     *
     * @type {update}
     */
    this.on('update', () => {
      // check frontend
      if (!this.eden.frontend) return;

      // check type
      if (opts.type !== this.type || (opts.placement || {}).id !== this.placement.get('id')) {
        // set type
        this.type   = opts.type;
        this.blocks = (opts.placement || {}).render || [];

        // trigger mount
        this.trigger('mount');
      }
    });

    /**
     * on mount
     *
     * @type {mount}
     */
    this.on('mount', () => {
      // check frontend
      if (!this.eden.frontend) return;

      // init dragula
      if (!this.dragula) this.initDragula();

      // set placement
      this.placement = opts.placement ? this.model('placement', opts.placement) : this.model('placement', {});
        
      // check blocks
      if ((this.placement.get('blocks') || []).length !== this.blocks.length) {
        // load blocks
        this.loadBlocks(this.placement);
      }

      // loads block
      socket.on('placement.' + this.placement.get('id') + '.block', (block) => {
        // get found
        let found = this.blocks.find((b) => b.uuid === block.uuid);

        // check found
        if (!found) {
          // push
          this.blocks.push(block);

          // return update
          return this.update();
        }

        // set values
        for (let key in block) {
          // set value
          found[key] = block[key];
        }

        // update
        this.update();
      });
    });
  </script>
</eden-update>