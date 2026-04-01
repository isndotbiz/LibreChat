const { Tool } = require('@langchain/core/tools');
const { runHydraCLI } = require('./HydraCLI');

const hydraIPScoreSchema = {
  type: 'object',
  properties: {
    model: {
      type: 'string',
      description: 'Model identifier to score.',
    },
  },
  required: ['model'],
};

class HydraIPScore extends Tool {
  name = 'hydra_ip_score';
  description =
    'Return HYDRA model IP score, evaluation count, confidence level, and top techniques for a model.';
  schema = hydraIPScoreSchema;

  static get jsonSchema() {
    return hydraIPScoreSchema;
  }

  async _call(input) {
    const { model } = input ?? {};
    if (!model || typeof model !== 'string') {
      throw new Error('`model` is required for hydra_ip_score');
    }
    return runHydraCLI('hydra_ip_score.py', ['--model', model]);
  }
}

module.exports = HydraIPScore;
