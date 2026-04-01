const manifest = require('./manifest');

// Structured Tools
const DALLE3 = require('./structured/DALLE3');
const FluxAPI = require('./structured/FluxAPI');
const HydraStatus = require('./structured/HydraStatus');
const HydraIPScore = require('./structured/HydraIPScore');
const HydraEvaluate = require('./structured/HydraEvaluate');
const HydraTechniques = require('./structured/HydraTechniques');
const OpenWeather = require('./structured/OpenWeather');
const StructuredWolfram = require('./structured/Wolfram');
const StructuredACS = require('./structured/AzureAISearch');
const StructuredSD = require('./structured/StableDiffusion');
const GoogleSearchAPI = require('./structured/GoogleSearch');
const TraversaalSearch = require('./structured/TraversaalSearch');
const createOpenAIImageTools = require('./structured/OpenAIImageTools');
const TavilySearchResults = require('./structured/TavilySearchResults');
const createGeminiImageTool = require('./structured/GeminiImageGen');

module.exports = {
  ...manifest,
  // Structured Tools
  DALLE3,
  FluxAPI,
  HydraStatus,
  HydraIPScore,
  HydraEvaluate,
  HydraTechniques,
  OpenWeather,
  StructuredSD,
  StructuredACS,
  GoogleSearchAPI,
  TraversaalSearch,
  StructuredWolfram,
  TavilySearchResults,
  createOpenAIImageTools,
  createGeminiImageTool,
};
