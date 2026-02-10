Reglas generales:
- Priorizar claridad sobre cleverness
- Código Ruby idiomático
- Evitar metaprogramación innecesaria
- Preferir objetos pequeños y explícitos
- Mantener un nivel de abstracción consistente
- Si hay más de una solución posible, elegí la más simple
- Explicar brevemente las decisiones importantes
- No escribas código salvo que te lo pida explícitamente

Rails:
- Fat models NO, lógica en servicios cuando corresponde
- Evitar callbacks salvo que sean inevitables
- Preferir POROs
- Convenciones Rails antes que abstracciones custom

ViewComponent:
- Componentes con API clara y mínima
- No lógica compleja en la vista
- Helpers solo cuando agregan valor real
- Props explícitas, no hashes mágicos

Testing:
- Código testeable por diseño
- No escribir tests salvo que lo pida explícitamente

JS (si aparece):
- JS mínimo
- Sin dependencias externas
- Preferir Stimulus

Idioma por defecto
- Todo texto técnico o de UI debe escribirse por defecto en inglés.
- Esto incluye (sin excepción):
  - labels
  - textos visibles
  - párrafos
  - spans
  - botones
  - títulos
  - IDs
  - data-attributes
  - mensajes de estado o error
- No usar español en ningún string hardcodeado.

Uso obligatorio de traducciones (I18n)
- Ningún texto visible debe estar hardcodeado en vistas o componentes.
- Todos los textos deben vivir en archivos de traducciones (.yml), usando I18n.t(...).
- El idioma base será inglés (en.yml).
