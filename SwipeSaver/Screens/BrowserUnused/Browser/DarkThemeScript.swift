//
//  File.swift
//  SurfShield
//
//  Created by Артур Кулик on 05.10.2025.
//

import Foundation

class DarkThemeScript {
    
    
    /// Возвращает JavaScript код для белого текста и черных фонов
    static var darkThemeScript: String {
        return """
        (function() {
            'use strict';

            console.log('🎨 SurfShield: Запуск упрощенного скрипта темной темы...');

            // Функция для проверки, светлый ли цвет
            function isLightColor(color) {
                if (!color || color === 'transparent' || color === 'rgba(0, 0, 0, 0)') {
                    return false;
                }
                
                const rgbMatch = color.match(/rgba?\\((\\d+),\\s*(\\d+),\\s*(\\d+)/);
                if (!rgbMatch) return false;
                
                const r = parseInt(rgbMatch[1], 10);
                const g = parseInt(rgbMatch[2], 10);
                const b = parseInt(rgbMatch[3], 10);

                // Вычисляем яркость (luminance)
                const luminance = (0.299 * r + 0.587 * g + 0.114 * b) / 255;

                // Считаем цвет светлым, если яркость больше 0.85 (85%) - более консервативно
                return luminance > 0.85;
            }

            // Применяем темную тему к фону, сохраняя цвет текста
            function applyDarkTheme() {
                document.querySelectorAll('*').forEach(el => {
        
        
                    const style = getComputedStyle(el);

                    if (style.backgroundColor && isLightColor(style.backgroundColor)) {
                        el.style.setProperty('background-color', '#1D1C22', 'important');
                    }

                    if (style.borderColor && isLightColor(style.borderColor)) {
                        el.style.setProperty('border-color', '#CCCCCC', 'important');
                    }

                    // Заменяем тени на черные
                    if (style.boxShadow && style.boxShadow !== 'none') {
                        el.style.setProperty('box-shadow', '0 2px 8px rgba(0, 0, 0, 0.3)', 'important');
                    }
                    if (style.textShadow && style.textShadow !== 'none') {
                        el.style.setProperty('text-shadow', '0 1px 2px rgba(0, 0, 0, 0.5)', 'important');
                    }

                    if (!isLightColor(style.color)) {
                        el.style.setProperty('color', '#D4D4E8', 'important');
                    }
                });

                // Общий фон и текст на body/html
                if (document.body) {
                    document.body.style.setProperty('background-color', '#1D1C22', 'important');
                    document.body.style.setProperty('color', '#D4D4E8', 'important');
                }
                if (document.documentElement) {
                    document.documentElement.style.setProperty('background-color', '#1D1C22', 'important');
                    document.documentElement.style.setProperty('color', '#D4D4E8', 'important');
                }

                console.log('✅ SurfShield: Темная тема применена, включая верхние слои');
            }


            // Применяем мгновенно
            applyDarkTheme();
            
            // Применяем при загрузке DOM
            if (document.readyState === 'loading') {
                document.addEventListener('DOMContentLoaded', function() {
                    applyDarkTheme();
                });
            }
            
            // Применяем при полной загрузке
            window.addEventListener('load', function() {
                applyDarkTheme();
            });
            
            // Применяем при изменении DOM (для динамического контента)
            if (window.MutationObserver) {
                const observer = new MutationObserver(function(mutations) {
                    mutations.forEach(function(mutation) {
                        if (mutation.type === 'childList') {
                            mutation.addedNodes.forEach(function(node) {
                                if (node.nodeType === 1) { // Element node
                                    // Применяем темную тему к новому элементу
                                    const style = getComputedStyle(node);
                                    
                                    if (style.backgroundColor && isLightColor(style.backgroundColor)) {
                                        node.style.setProperty('background-color', '#1D1C22', 'important');
                                    }
                                    
                                    if (style.borderColor && isLightColor(style.borderColor)) {
                                        node.style.setProperty('border-color', '#CCCCCC', 'important');
                                    }
                                    
                                    // Заменяем тени на черные
                                    if (style.boxShadow && style.boxShadow !== 'none') {
                                        node.style.setProperty('box-shadow', '0 2px 8px rgba(0, 0, 0, 0.3)', 'important');
                                    }
                                    if (style.textShadow && style.textShadow !== 'none') {
                                        node.style.setProperty('text-shadow', '0 1px 2px rgba(0, 0, 0, 0.5)', 'important');
                                    }
                                    
                                    if (!isLightColor(style.color)) {
                                        node.style.setProperty('color', '#D4D4E8', 'important');
                                    }
                                    
                                    // Применяем к дочерним элементам
                                    const children = node.querySelectorAll('*');
                                    children.forEach(function(child) {
                                        const childStyle = getComputedStyle(child);
                                        
                                        if (childStyle.backgroundColor && isLightColor(childStyle.backgroundColor)) {
                                            child.style.setProperty('background-color', '#1D1C22', 'important');
                                        }
                                        
                                        if (childStyle.borderColor && isLightColor(childStyle.borderColor)) {
                                            child.style.setProperty('border-color', '#CCCCCC', 'important');
                                        }
                                        
                                        // Заменяем тени на черные
                                        if (childStyle.boxShadow && childStyle.boxShadow !== 'none') {
                                            child.style.setProperty('box-shadow', '0 2px 8px rgba(0, 0, 0, 0.3)', 'important');
                                        }
                                        if (childStyle.textShadow && childStyle.textShadow !== 'none') {
                                            child.style.setProperty('text-shadow', '0 1px 2px rgba(0, 0, 0, 0.5)', 'important');
                                        }
                                        
                                        if (!isLightColor(childStyle.color)) {
                                            child.style.setProperty('color', '#D4D4E8', 'important');
                                        }
                                    });
                                }
                            });
                        }
                    });
                });
                
                observer.observe(document.body || document.documentElement, {
                    childList: true,
                    subtree: true
                });
            }
            
            console.log('SurfShield: Темная тема применена МГНОВЕННО');

            // Применять повторно при динамических изменениях и скролле можно дополнительно
        })();

        """
    }
}
