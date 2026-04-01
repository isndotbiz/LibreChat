const { Tool } = require('@langchain/core/tools');
const { runHydraCLI } = require('./HydraCLI');

const hydraTechniquesSchema = {
  type: 'object',
  properties: {
    category: {
      type: 'string',
      description: 'Optional category filter.',
    },
    model_family: {
      type: 'string',
      description: 'Optional model family filter.',
    },
    limit: {
      type: 'integer',
      minimum: 1,
      maximum: 50,
      description: 'Maximum number of techniques to return.',
    },
  },
};

class HydraTechniques extends Tool {
  name = 'hydra_techniques';
  description = 'List top HYDRA jailbreak techniques by win rate and usage.';
  schema = hydraTechniquesSchema;

  static get jsonSchema() {
    return hydraTechniquesSchema;
  }

  async _call(input) {
    const { category, model_family: modelFamily, limit } = input ?? {};
    const args = [];
    if (category) {
      args.push('--category', category);
    }
    if (modelFamily) {
      args.push('--model-family', modelFamily);
    }
    if (limit) {
      args.push('--limit', String(limit));
    }
    return runHydraCLI('hydra_techniques.py', args);
  }
}

module.exports = HydraTechniques;
