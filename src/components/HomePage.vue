<template>
  <div class="app">
    <div v-if="showOverlayer" class="overlayer">
      <div class="overlayer--body">
        <h3>Recognizing...</h3>
      </div>
    </div>
    <div class="container">
      <div class="container--step step1">
        <h3>STEP 1 - Upload file</h3>
        <input type="file" @change="upload"/>
      </div>

      <div class="container--step step2">
        <h3>STEP 2 - Select your information</h3>
        <select v-model="selected">
          <option disabled value="">Please file type</option>
          <option value="default">Default</option>
          <option value="invoice">Invoice</option>
        </select>
        <!--selector for invoice-->
        <div v-if="selected == 'invoice' && text">
          <input type="checkbox" v-model="options" value="pageNum">pageNum
          <input type="checkbox" v-model="options" value="id">id
          <input type="checkbox" v-model="options" value="ttc">ttc
          <input type="checkbox" v-model="options" value="ht">ht
          <input type="checkbox" v-model="options" value="tva">tva
          <div>You have selected:{{options}}</div>
        </div>
        <p>{{text}}</p>
        <div id="imgDiv"></div>
      </div>

      <div class="container--step step3">
        <h3>STEP 3 - Find your information here</h3>
        <div class="step3--card" v-for="element in options" :key="element">
          <span v-if="element == 'pageNum'">Page:{{invoice.pageNum}}</span>
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
          if(element != 'pageNum') {
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
        if(file.size <= 2000000) {
          //if format is pdf
          this.showOverlayer = true;
          if(file.type.indexOf('pdf')>-1) {
            this.recognizePdf(file);
          }else {
            this.recognizeImage(file);
          }
        }else {
          alert ('The uploaded file should not be over 2M!')
        }
      },
      recognizePdf(file) {
        var reader = new FileReader();
        var scale = 2;
        reader.readAsArrayBuffer(file);
        reader.addEventListener("load",  () => {
          PDFJS.getDocument(reader.result).then((pdf) => {
            var pageNum = pdf.numPages;
            this.invoice.pageNum = pageNum;

            for(var i = 1; i <= pageNum; i++) {
              var canvas = document.createElement('canvas');
              canvas.id = "pageNum" + i;
              var imageDiv = document.getElementById('imgDiv');
              // imageDiv.append(canvas);
              var context = canvas.getContext('2d');
              pdf.getPage(pageNum).then((page) => {
                var viewport = page.getViewport(scale); // reference canvas via context
                var canvasObj = context.canvas;
                canvasObj.width = viewport.width;
                canvasObj.height = viewport.height;
                canvasObj.style.width = "100%";
                canvasObj.style.height = "100%";
                var renderContext = {
                  canvasContext: context,
                  viewport: viewport
                };
                page.render(renderContext).then(() => {
                  return page.getTextContent()
                }).then(() => {
                  var url = canvas.toDataURL("image/png");
                  const img = document.createElement('img');
                  img.id = "pageNum" + i;
                  img.src = url;
                  img.style.width = '100%';
                  img.style.height = '100%';
                  img.style.boxShadow = '0px 0px 5px #888888';
                  imageDiv.append(img);
                  try {
                    worker.recognize(img).then((result) => {
                      this.text += result.data.text;
                      this.showOverlayer = false
                    });
                  }catch (error) {
                    alert (error)
                  }
                });
              })
            }
          })
        }, false)
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
          case('id'):
            reqG = /FACTURE/gi;
            reqS = /FACTURE(.*)/gi;
            break;
          case('ht'):
            reqG = /HT/gi;
            reqS = /HT(.*)/gi;
            break;
          case('ttc'):
            reqG = /TTC/gi;
            reqS = /TTC(.*)/gi;
            break;
          case('tva'):
            reqG = /TVA/gi;
            reqS = /TVA(.*)/gi;
            break;
          default:
        }
        var idTimes = textCache.match(reqG);

        for(let i=0; i<idTimes.length; i++) {
          let option = textCache.match(reqS)[0].slice(0,40);
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
  }
  .step1 {
    width: 20%;
  }
  .step2, .step3 {
    width: 40%;
  }
  .step3--card {
    margin: 15px;
    padding: 5px;
    box-shadow: 0 0 5px #888888;
    border-radius: 10px;
  }
</style>
