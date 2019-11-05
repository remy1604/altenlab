<template>
  <div class="app">
    <div v-if="showOverlayer" class="overlayer">
      <div class="overlayer--body">
        <h3>Recognizing...</h3>
      </div>
    </div>
    <h1>AltenLab-OCR platform</h1>
    <div class="container">
      <div class="container--step">
        <div class="container--step--up">
          <h3>STEP 1 - Upload file</h3>
          <input type="file" @change="upload"/>
          <p>Supported formats: jpg, png, pdf, tiff</p>
          <p>Max file size: 10Mb</p>
        </div>

        <div v-show="text" class="card-round">
          <p>Uploaded File :</p>
          <div id="imgDiv"></div>
        </div>
      </div>

      <div class="container--step">
        <div class="container--step--up">
          <h3>STEP 2 - Select your information</h3>
          <select v-model="selected">
            <option disabled value="">Please file type</option>
            <option value="default">Default</option>
            <option value="invoice">Invoice</option>
          </select>
          <!--selector for invoice-->
          <div v-if="selected == 'invoice' && text">
            <input type="checkbox" v-model="options" value="Page quantity">Page quantity
            <input type="checkbox" v-model="options" value="Invoice number">Invoice number
            <input type="checkbox" v-model="options" value="TTC">TTC
            <input type="checkbox" v-model="options" value="HT">HT
            <input type="checkbox" v-model="options" value="TVA">TVA
            <div class="options">You have selected:
              <ul>
                <li v-for="element in options" :key="element">
                  {{element}}
                </li>
              </ul>
            </div>
          </div>
        </div>

        <div v-if="text" class="card-round">
          <p>Recognized Text:</p>
          <p>{{text}}</p>
        </div>
      </div>

      <div class="container--step">
        <div class="container--step--up">
          <h3>STEP 3 - Find your information here</h3>
          <p>Find below all the possible results according to your choices in step 2</p>
        </div>
        <div class="card-round" v-for="element in options" :key="element">
          <span v-if="element == 'Page quantity'">Page:{{invoice.pageNum}}</span>
          <div v-else>
            <p>{{element}} result:</p>
            <ul>
              <li v-for="result in invoice[element]" :key="result">{{result}}</li>
            </ul>
          </div>
        </div>
      </div>
    </div>

  </div>
</template>

<script>
  /* eslint-disable */
  import { createWorker, PSM, OEM } from 'tesseract.js';
  const worker = createWorker({
    logger: m => {}
  });

  import PDFJS from 'pdfjs-dist';
  PDFJS.GlobalWorkerOptions.workerSrc = 'pdfjs-dist/build/pdf.worker.js';

  import Tiff from 'tiff.js';

  export default {
    name: 'app',
    data() {
      return {
        selected: '',
        showOverlayer: false,
        text: '',
        invoice: {
          pageNum: 1,
          id: [],
          ttc: [],
          ht: [],
          tva: []
        },
        options: []
      }
    },
    watch: {
      options() {
        this.options.forEach(element => {
          if(element != 'Page quantity') {
            this.invoice[element] = this.matchInfo(element)
          }
        })
      }
    },
    methods: {
      async upload(e) {
        await worker.load();
        await worker.loadLanguage('eng+fra');
        await worker.initialize('fra', OEM.LSTM_ONLY);
        await worker.setParameters({
          tessedit_pageseg_mode: PSM.SINGLE_BLOCK,
        });
        const file = e.target.files[0];
        if(file.size <= 10000000) {
          //if format is pdf
          this.showOverlayer = true;
          if(file.type.indexOf('pdf')>-1) {
            this.recognizePdf(file);
          }else if(file.type.indexOf('tif')>-1 || file.type.indexOf('tiff')>-1) {
            this.recognizeTiff(file)
          }
          else {
            this.recognizeImage(file);
          }
        }else {
          alert ('The uploaded file should not be over 10Mb!')
        }
      },
      recognizeTiff(file) {
        var reader = new FileReader();
        reader.readAsArrayBuffer(file);
        reader.addEventListener("load",  () => {
          var tiff = new Tiff({buffer: reader.result});
          var pageNum = tiff.countDirectory();
          this.invoice.pageNum = pageNum;
          for (var i = 0; i < pageNum; ++i) {
            tiff.setDirectory(i);
            var canvas = tiff.toCanvas();
            canvas.style.width = "100%";
            canvas.style.height = "100%";
            canvas.style.boxShadow = '0px 0px 5px #888888';
            const imageDiv = document.getElementById('imgDiv');
            imageDiv.append(canvas);
            try {
              worker.recognize(canvas).then((result) => {
                this.text += result.data.text;
                this.showOverlayer = false
              });
            }catch (error) {
              alert (error)
            }
          }
        })
      },
      recognizePdf(file) {
        var reader = new FileReader();
        reader.readAsArrayBuffer(file);
        reader.addEventListener("load",  () => {
          PDFJS.getDocument(reader.result).then((pdf) => {
            var pageNum = pdf.numPages;
            this.invoice.pageNum = pageNum;
            const imageDiv = document.getElementById('imgDiv');
            for(var i = 1; i <= pageNum; i++) {
              var canvas = document.createElement('canvas');
              canvas.id = "pageNum" + i;
              imageDiv.append(canvas);
              const context = canvas.getContext('2d');
              this.canvas2img(pdf, i, context, canvas);
            }
          })
        }, false)
      },
      canvas2img(pdf, pageNum, context, canvas) {
        var scale = 2;
        pdf.getPage(pageNum).then((page) => {
          var viewport = page.getViewport(scale); // reference canvas via context
          var canvasObj = context.canvas;
          canvasObj.width = viewport.width;
          canvasObj.height = viewport.height;
          canvasObj.style.width = "100%";
          canvasObj.style.height = "100%";
          canvasObj.style.boxShadow = '0px 0px 5px #888888';
          var renderContext = {
            canvasContext: context,
            viewport: viewport
          };
          page.render(renderContext).then(() => {
            try {
              worker.recognize(canvas).then((result) => {
                this.text += result.data.text;
                this.showOverlayer = false
              });
            }catch (error) {
              alert (error)
            }
          });
        })
      },
      recognizeImage(file) {
        var imageDiv = document.getElementById('imgDiv');
        var reader = new FileReader();
        reader.readAsDataURL(file);
        reader.addEventListener("load", () => {
          const img = document.createElement('img');
          img.src = reader.result;
          img.style.width = '100%';
          img.style.height = '100%';
          img.style.boxShadow = '0px 0px 5px #888888';
          imageDiv.append(img);
          try {
            worker.recognize(img).then((result) => {
              this.text = result.data.text;
              this.showOverlayer = false
            });
          }catch (error) {
            alert (error)
          }
        }, false);
      },
      matchInfo(val) {
        var textCache = this.text;

        var result = [];
        var reqG;
        var reqS;
        switch(val) {
          case('Invoice number'):
            reqG = /FACTURE/gi;
            reqS = /FACTURE(.*)/gi;
            break;
          case('HT'):
            reqG = /HT/gi;
            reqS = /HT(.*)/gi;
            break;
          case('TTC'):
            reqG = /TTC/gi;
            reqS = /TTC(.*)/gi;
            break;
          case('TVA'):
            reqG = /TVA/gi;
            reqS = /TVA(.*)/gi;
            break;
          default:
        }
        var idTimes = textCache.match(reqG);

        for(let i=0; i<idTimes.length; i++) {
          let option = textCache.match(reqS)[0].slice(0,50);
          result.push(option);
          textCache = textCache.replace(option, '');
        }
        return result
      },
    }
  }
</script>

<style>
  .app {
    font-family: 'Avenir', Helvetica, Arial, sans-serif;
    -webkit-font-smoothing: antialiased;
    -moz-osx-font-smoothing: grayscale;
    text-align: center;
    color: #2c3e50;
  }
  .overlayer {
    width: 100%;
    height: 100vh;
    overflow: hidden;
    z-index: 99;
    background-color: rgba(0, 0, 0, 0.7);
    position: fixed;
    left: 0;
    top: 0;
    display: flex;
    justify-content: center;
    align-items: center;
  }
  .overlayer--body {
    z-index: 100;
    width: 200px;
    height: 50px;
    border-radius: 25px;
    background: white;
    display: flex;
    justify-content: center;
    align-items: center;
  }
  .container {
    display: flex;
    justify-content: center;
    width: 100%;
    height: 100%;
    overflow: auto;
  }
  .container--step {
    margin: 20px;
    width: 33%;
  }
  .container--step--up {
    min-height: 254px;
  }
  .card-round {
    margin: 15px;
    padding: 5px;
    box-shadow: 0 0 5px #888888;
    border-radius: 10px;
  }
  .options {
    margin-top: 20px;
    width: 50%;
  }
</style>
