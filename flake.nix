{
  description = "Claude personality profiles for different thinking modes";
  outputs = { self, nixpkgs }:
    let
      system = "x86_64-darwin";  # macOS用に変更
      pkgs = nixpkgs.legacyPackages.${system};
      
      # 共通の開発ツール
      commonPackages = with pkgs; [
        jdk17
        clojure
        jq
        shellspec
        direnv
        tmux
      ];
      
      # 利用可能な personalities のリスト（ここだけ編集すればOK）
      personalities = [ "architect" "e2etester" "validator" "executor" "tester" "specifier" ];
      
      # 共通のシェル機能（personality切り替え関数）
      commonShellHook = ''
        export PERSONALITIES_DIR=".claude-personalities"
        mkdir -p "$PERSONALITIES_DIR"
        
        # ハッシュクリアを強制
        hash -d git 2>/dev/null || true
        # 通常のcommit: --no-verifyを除去
        git() {
            local subcommand="$1"
            
            case "$subcommand" in
                "commit")
                    local clean_args=()
                    for arg in "$@"; do
                        if [[ "$arg" != "--no-verify" && "$arg" != "-n" ]]; then
                            clean_args+=("$arg")
                        fi
                    done
                    command git "''${clean_args[@]}"
                    ;;
                    
                "dangerous-commit")
                    shift
                    echo "⚠️  Dangerous commit: allowing --no-verify"
                    command git commit "$@"
                    ;;
                    
                *)
                    command git "$@"
                    ;;
            esac
        }
        
        # personality切り替え関数
        switch_personality() {
          local target_personality="$1"
          if [ -z "$target_personality" ]; then
            echo "🎭 Available personalities:"
            ${pkgs.lib.concatMapStringsSep "\n" (p: "echo \"  - ${p}\"") personalities}
            echo ""
            echo "Usage: switch_personality <n>"
            return 1
          fi
          
          local personality_file="$PERSONALITIES_DIR/CLAUDE.$target_personality.md"
          
          # ファイルが存在しない場合は作成
          if [ ! -f "$personality_file" ]; then
            # 既存のファイルから複製を試行
            local existing_file=$(find "$PERSONALITIES_DIR" -name "CLAUDE.*.md" -type f | head -n 1)
            if [ -n "$existing_file" ]; then
              echo "📋 Copying from existing file: $(basename "$existing_file")"
              cp "$existing_file" "$personality_file"
            else
              echo "📝 Creating default CLAUDE.$target_personality.md..."
              cat > "$personality_file" << 'EOF'
# Claude $target_personality Personality

<!-- Write your personality prompt here -->
EOF
            fi
          fi
          
          # シンボリックリンクを更新
          ln -sf "$personality_file" "CLAUDE.md"
          
          # 環境変数を更新
          export CLAUDE_PERSONALITY="$target_personality"
          
          echo "🧠 Switched to Claude $target_personality personality"
          echo "📁 Profile: $personality_file"
          echo "🔗 Linked to: ./CLAUDE.md"
        }
        
        # personality一覧表示関数
        list_personalities() {
          echo "🎭 Available personalities:"
          ${pkgs.lib.concatMapStringsSep "\n" (p: "echo \"  - ${p}\"") personalities}
          echo ""
          echo "Current: ''${CLAUDE_PERSONALITY:-none}"
        }
        
        # エイリアス
        alias sp=switch_personality
        alias lp=list_personalities

        alias cco="claude --dangerously-skip-permissions"
      '';
      
      # 性格プロファイルを作成する関数
      makeClaudePersonality = name: defaultContent: pkgs.mkShell {
        name = "claude-${name}";
        buildInputs = commonPackages;
        shellHook = ''
          ${commonShellHook}
          
          # 初期personality設定
          switch_personality "${name}"
          
          echo ""
          echo "💡 Commands:"
          echo "  switch_personality <n> (or sp) - Switch personality"
          echo "  list_personalities (or lp)       - List personalities"
          echo "  claude <your prompt>              - Use Claude"
        '';
      };
    in {
      devShells.${system} = {
        # デフォルトシェル
        default = pkgs.mkShell {
          name = "claude-personality-manager";
          buildInputs = commonPackages;
          shellHook = ''
            ${commonShellHook}
            
            echo "🎭 Claude Personality Manager"
            echo ""
            echo "💡 Commands:"
            echo "  switch_personality <n> (or sp) - Switch personality"
            echo "  list_personalities (or lp)       - List personalities"
            echo ""
            echo "🎯 Available personalities:"
            ${pkgs.lib.concatMapStringsSep "\n" (p: "echo \"  - ${p}\"") personalities}
            echo ""
            echo "Example: sp architect"
          '';
        };
      } 
      # personalities リストから自動的にdevShellsを生成
      // pkgs.lib.genAttrs personalities (name: 
        makeClaudePersonality name "# Claude ${name} Personality\n\nDescribe your ${name} personality here."
      );
    };
}