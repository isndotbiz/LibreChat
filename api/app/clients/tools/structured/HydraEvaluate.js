const { Tool } = require('@langchain/core/tools');
const { runHydraCLI } = require('./HydraCLI');

const hydraEvaluateSchema = {
  type: 'object',
  properties: {
    message: {
      type: 'string',
      description: 'User prompt to evaluate with HYDRA.',
    },
    model: {
      type: 'string',
      description: 'Optional target model identifier.',
    },
  },
  required: ['message'],
};

class HydraEvaluate extends Tool {
  name = 'hydra_evaluate';
  description =
    'Run HYDRA evaluation cascade on a prompt and return result metadata, technique, and quality score.';
  schema = hydraEvaluateSchema;

  static get jsonSchema() {
    return hydraEvaluateSchema;
  }

  async _call(input) {
    const { message, model } = input ?? {};
    if (!message || typeof message !== 'string') {
      throw new Error('`message` is required for hydra_evaluate');
    }

    const args = ['--message', message];
    if (model) {
      args.push('--model', model);
    }

    return runHydraCLI('hydra_evaluate.py', args);
  }
}

module.exports = HydraEvaluate;
