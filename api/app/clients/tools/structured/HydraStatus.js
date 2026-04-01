const { Tool } = require('@langchain/core/tools');
const { runHydraCLI } = require('./HydraCLI');

const hydraStatusSchema = {
  type: 'object',
  properties: {},
};

class HydraStatus extends Tool {
  name = 'hydra_status';
  description =
    'Check HYDRA data-plane health and return PostgreSQL connectivity, counts, and last evaluation timestamp.';
  schema = hydraStatusSchema;

  static get jsonSchema() {
    return hydraStatusSchema;
  }

  async _call() {
    return runHydraCLI('hydra_status.py');
  }
}

module.exports = HydraStatus;
