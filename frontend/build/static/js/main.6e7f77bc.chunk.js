(this["webpackJsonpeve-bpc-avg-frontend"]=this["webpackJsonpeve-bpc-avg-frontend"]||[]).push([[0],{206:function(e,t,a){"use strict";a.r(t);var r=a(0),n=a.n(r),s=a(79),i=a.n(s),o=a(13),c=a(1),u=a(8),l=a(9),d={body:{fontFamily:'"Titillium Web", sans-serif',height:"100%",background:"url(/assets/images/bg.jpg) top center no-repeat",backgroundSize:"100%"},html:{height:"100%",overflow:"visible"}},p={common:{volume:.25}},m={object:{src:["/assets/sounds/object.mp3"]},assemble:{src:["/assets/sounds/assemble.mp3"],loop:!0},type:{src:["/assets/sounds/type.mp3"],loop:!0},click:{src:["/assets/sounds/click.mp3"]},ask:{src:["/assets/sounds/ask.mp3"]},error:{src:["/assets/sounds/error.mp3"]},info:{src:["/assets/sounds/information.mp3"]},readout:{src:["/assets/sounds/readout.mp3"]},toggle:{src:["/assets/sounds/toggle.mp3"]},warning:{src:["/assets/sounds/warning.mp3"]}},h={object:{player:"object"},assemble:{player:"assemble"},type:{player:"type"},click:{player:"click"},ask:{player:"ask"},error:{player:"error"},info:{player:"info"},readout:{player:"readout"},toggle:{player:"toggle"},warning:{player:"warning"}},b=a(23),j=a(18),f=a.n(j),g="http://localhost:1339";function y(e){return x.apply(this,arguments)}function x(){return(x=Object(b.a)(f.a.mark((function e(t){var a;return f.a.wrap((function(e){for(;;)switch(e.prev=e.next){case 0:return e.prev=0,e.next=3,fetch("".concat(g,"/estimate"),{method:"post",headers:{"Content-Type":"application/json"},body:JSON.stringify(t)});case 3:return a=e.sent,e.abrupt("return",a.json());case 7:return e.prev=7,e.t0=e.catch(0),console.error("req err",e.t0),e.abrupt("return",{ok:!1});case 11:case"end":return e.stop()}}),e,null,[[0,7]])})))).apply(this,arguments)}var v=function(e,t){var a=Object(r.useState)(!1),n=Object(o.a)(a,2),s=n[0],i=n[1],c=function(){var a=Object(b.a)(f.a.mark((function a(r){var n,s;return f.a.wrap((function(a){for(;;)switch(a.prev=a.next){case 0:return r.preventDefault(),i(!0),a.next=4,y(e);case 4:n=a.sent,s=!1!==n.ok,i(!1),s?t(null,n):t(n);case 8:case"end":return a.stop()}}),a)})));return function(e){return a.apply(this,arguments)}}();return{isPendingEstimate:s,submitEstimate:c}},O=a(3),k=[{id:"typeID",data:"typeID"},{id:"typeName",data:"Name"},{id:"minSoloPrice_human",data:"Solo"},{id:"minPackagePrice_human",data:"Package"},{id:"minMarketPrice_human",data:"Market"},{id:"marketLiquidity_human",data:"Liquidity"},{id:"minPrice_human",data:"Lowest Price"},{id:"itemsFound",data:"Your Quantity"},{id:"totalMarketValue_human",data:"Your Value"},{id:"marketType",data:"Method"},{id:"minPriceRegionName",data:"Region"}],w=["6%","40%","6%","6%","6%","6%","6%","6%","6%","6%","6%"],S=function(e){var t=n.a.useState(!0),a=Object(o.a)(t,2),r=a[0];a[1];n.a.useEffect((function(){return function(){return clearTimeout(0)}}),[r]);var s=e.estimate.items.map((function(e){return{id:"item_"+e.typeID,columns:k.map((function(t){return{id:"item_"+e.typeID+"_"+t.id,data:null===e[t.id]?"":String(e[t.id])}}))}}));return e.estimate.items.length?Object(O.jsxs)("div",{children:[Object(O.jsxs)("center",{children:[Object(O.jsx)("h3",{children:"Your Total Value:"}),Object(O.jsxs)("h1",{class:"hilite",children:[e.estimate.totalMarketValue_human," ISK"]})]}),Object(O.jsx)(l.Table,{animator:{activate:r},headers:k,dataset:s,columnWidths:w})]}):""},P={duration:{enter:1e3,exit:1e3}},T=function(e){var t=e.children,a=Object(u.useBleeps)();return Object(O.jsx)(l.Button,{onClick:function(){return a.readout.play()},FrameComponent:l.FrameCorners,style:{margin:"auto",float:"right"},children:Object(O.jsx)(l.Text,{children:t})})},_=function(){var e=n.a.useState(!0),t=Object(o.a)(e,2),a=t[0],r=(t[1],n.a.useState({})),s=Object(o.a)(r,2),i=s[0],b=s[1],j=n.a.useState({items:[]}),f=Object(o.a)(j,2),g=f[0],y=f[1];n.a.useEffect((function(){return function(){return clearTimeout(0)}}),[a]);var x=v(i,(function(e,t){e?console.error("error",e):y(t)})).submitEstimate;return Object(O.jsxs)(l.ArwesThemeProvider,{children:[Object(O.jsx)(l.StylesBaseline,{styles:{html:d.html,body:d.body,".arwes-text-field":{marginBottom:20},form:{width:"750px",margin:"0 auto 50px auto",paddingTop:"50px"},textarea:{maxHeight:"200px",height:"200px"},".hilite":{color:"#F8F800"}}}),Object(O.jsx)(u.BleepsProvider,{audioSettings:p,playersSettings:m,bleepsSettings:h,children:Object(O.jsxs)(c.AnimatorGeneralProvider,{animator:P,children:[Object(O.jsx)("form",{onSubmit:x,children:Object(O.jsxs)(l.FrameHexagon,{animator:{activate:a},hover:!0,inverted:!0,children:[Object(O.jsx)(l.TextField,{multiline:!0,placeholder:"Paste EVE inventory here",autoFocus:!0,defaultValue:"",spellCheck:!1,inputProps:{id:"paste"},onChange:function(e){b({paste:e.target.value})},style:{width:"700px",minHeight:"200px"}}),Object(O.jsx)(T,{children:"Appraise"})]})}),Object(O.jsx)(S,{estimate:g})]})})]})};i.a.render(Object(O.jsx)(_,{}),document.getElementById("root"))}},[[206,1,2]]]);
//# sourceMappingURL=main.6e7f77bc.chunk.js.map