{%- set var_name = "my_variable" -%}
{%- set var_value = "Hello, World" -%}

{{var_name}}  
{{var_value }}

{%set fruits =["apple","mango","grapes"] %}

{%- for i in fruits -%}
  {% if i!="mango"%}
    {{ i }}
  {%else%}
     I love {{ i }}  
  {% endif %}
{%endfor%} 
