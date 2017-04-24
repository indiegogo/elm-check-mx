let path              = require( 'path' );
let webpack           = require( 'webpack' )
let entryPath         = path.join(__dirname, 'src/js/index.js');
let outputPath        = path.join(__dirname, 'dist');
module.exports = {
  entry: [ entryPath ],
  output: {
    path: outputPath,
    filename: "./index.js"
  },
  resolve: {
    extensions: ['.js', '.elm']
  },
  module: {
    loaders: [{
      test: /\.elm$/,
      exclude: [/elm-stuff/, /node_modules/],
      loader: 'elm-webpack-loader'
    }]
  },
  plugins: [
    new webpack.optimize.UglifyJsPlugin({
      minimize:   true,
      compressor: { warnings: false }, // against my better judgment this is false because "compressing" elm emits a slew of warnings
  //    mangle:  true
    })
  ]
};
