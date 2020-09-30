tinymce.create('tinymce.plugins.BZRetainedFields', {
  init : function(ed, url) {
    function showFieldDialog(header, callback, editing) {
      var dialog = document.createElement("div");
      dialog.setAttribute("id", "bz-retained-field-dialog-holder");
      var div = document.createElement("div");
      div.setAttribute("id", "bz-retained-field-dialog");
      dialog.appendChild(div);

      var hdr = document.createElement("div");
      hdr.innerHTML = header;
      hdr.className = "bz-dialog-header";
      div.appendChild(hdr);

      var label = document.createElement("label");
      label.innerHTML = "<span>Field Name:</span> ";
      var name = document.createElement("input");
      name.type = "text";
      label.appendChild(name);
      div.appendChild(label);

      label = document.createElement("label");
      label.innerHTML = "<span>Optional? </span> ";
      var optional = document.createElement("input");
      optional.type = "checkbox";
      if(editing) {
        label.appendChild(optional);
        div.appendChild(label);
      }

      label = document.createElement("label");
      label.innerHTML = "<span>Type:</span> ";

      var type = document.createElement("select");
      var typeHtml = "<option value=\"input\">Single-line text</option><option value=\"textarea\">Multi-line text box</option><option value=\"checkbox\">Check box</option>";
      if(editing)
      	typeHtml += "<option value=\"radio\">Radio boxes</option>";
      type.innerHTML = typeHtml;

      label.appendChild(type);
      div.appendChild(label);

      label = document.createElement("label");
      label.innerHTML = "<span>Values:</span> ";
      var values = document.createElement("textarea");
      label.appendChild(values);
      div.appendChild(label);

      var valuesLabel = label;
      valuesLabel.style.display = "none";

      type.onchange = function() {
        if(type.options[type.selectedIndex].value == "radio")
          valuesLabel.style.display = "";
        else
          valuesLabel.style.display = "none";
      };



      var i = document.createElement("button");
      i.setAttribute("type", "button");
      i.className = "cancel";
      i.innerHTML = "Cancel";
      i.onclick = function() {
            dialog.parentNode.removeChild(dialog);
      };
      div.appendChild(i);


      var i = document.createElement("button");
      i.setAttribute("type", "button");
      i.className = "submit";
      i.innerHTML = "Insert";
      i.onclick = function() {
            if(name.value.length == 0)
              alert("You cannot use a magic field without a name. Please enter one.");
            else {
              callback(name.value, type.options[type.selectedIndex].value, values.value.split("\n"), optional.checked);
              dialog.parentNode.removeChild(dialog);
            }
      };
      div.appendChild(i);


      document.body.appendChild(dialog);
    }

    ed.addCommand('bzRetainedField', function() {
      showFieldDialog("Add Magic Field Editor", function(name, type, values, optional) {
        name = name.replace(/</g, '&lt;');
        name = name.replace(/"/g, '&quot;');

        if(type == "checkbox")
          ed.selection.setContent('<input type="checkbox" '+(optional ? 'class="bz-optional-magic-field"':'')+' data-bz-retained="'+name+'" />');
        else if(type == "radio") {
          for(var i = 0; i < values.length; i++) {
            var v = values[i].
              replace("&", "&amp;").
              replace("<", "&lt;").
              replace(">", "&gt;").
              replace("\"", "&quot;");
            ed.selection.setContent('<input type="radio" value="'+v+'" '+(optional ? 'class="bz-optional-magic-field"':'')+' data-bz-retained="'+name+'" /> ' + v + '<br>');
          }
        } else if(type == "input")
          ed.selection.setContent('<input type="text" '+(optional ? 'class="bz-optional-magic-field"':'')+' data-bz-retained="'+name+'" />');
        else if(type == "textarea")
          ed.selection.setContent('<textarea '+(optional ? 'class="bz-optional-magic-field"':'')+' data-bz-retained="'+name+'">&#8291;</textarea>');
      }, true);
    });
    ed.addCommand('bzRetainedFieldView', function() {
      showFieldDialog("Add Magic Field Viewer", function(name, type) {
        name = name.replace(/</g, '&lt;');
        name = name.replace(/"/g, '&quot;');
        if(type == "checkbox")
          ed.selection.setContent('<input type="checkbox" readonly="readonly" data-bz-retained="'+name+'" />');
        else
          ed.selection.setContent('<img src="data:image/gif;base64,R0lGODlhAQABAAAAACH5BAEKAAEALAAAAAABAAEAAAICTAEAOw==" class=\"bz-magic-viewer\" data-bz-retained="'+name+'"/>');
      }, false);
    });
    ed.addButton('bz_retained_field', {
      title: 'Add Retained Field Edit Box',
      image: url + '/button.png',
      cmd: 'bzRetainedField'
    });
    ed.addButton('bz_retained_field_view', {
      title: 'Add Retained Field Display',
      image: url + '/btn-magic-static.png',
      cmd: 'bzRetainedFieldView'
    });

  },

  getInfo : function() {
    return {
      longname : 'BZRetainedFields',
      version : tinymce.majorVersion + "." + tinymce.minorVersion
    };
  }
});

tinymce.PluginManager.add('bz_retained_fields', tinymce.plugins.BZRetainedFields);
