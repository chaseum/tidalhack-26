import SwiftUI
import PhotosUI
import UIKit

struct PetPhotosView: View {
    @EnvironmentObject var router: Router
    let photos = MockData.photos
    @State private var isShowingPhotoPicker = false
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var capturedImages: [UIImage] = []
    @State private var pickerError: String?
    
    let columns = [GridItem(.flexible()), GridItem(.flexible())]
    
    var body: some View {
        ZStack {
            PetPalBackground()
            
            VStack(spacing: 0) {
                HStack {
                    Button { router.pop() } label: {
                        Image(systemName: "chevron.left").foregroundColor(DesignTokens.Colors.textPrimary)
                    }
                    Text("Photo Gallery").font(DesignTokens.Typography.headline)
                    Spacer()
                    CircularIconButton(icon: "camera.fill") {
                        isShowingPhotoPicker = true
                    }
                }
                .padding()
                
                ScrollView {
                    if !capturedImages.isEmpty {
                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.s) {
                            Text("New Captures")
                                .font(DesignTokens.Typography.caption)
                                .foregroundColor(DesignTokens.Colors.textSecondary)
                            
                            LazyVGrid(columns: columns, spacing: 12) {
                                ForEach(capturedImages, id: \.self) { image in
                                    Image(uiImage: image)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                                        .aspectRatio(1, contentMode: .fill)
                                        .cornerRadius(DesignTokens.Radius.m)
                                        .clipped()
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, DesignTokens.Spacing.s)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                    
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(photos) { photo in
                            AsyncImage(url: URL(string: photo.url)) { image in
                                image.resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Color.gray.opacity(0.2)
                            }
                            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                            .aspectRatio(1, contentMode: .fill)
                            .cornerRadius(DesignTokens.Radius.m)
                            .clipped()
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignTokens.Radius.m)
                                    .stroke(DesignTokens.Colors.border, lineWidth: 1)
                            )
                            .overlay(
                                Image(systemName: photo.isFavorite ? "heart.fill" : "heart")
                                    .foregroundColor(photo.isFavorite ? .pink : .white)
                                    .padding(8)
                                    .background(Color.black.opacity(0.2))
                                    .clipShape(Circle())
                                    .padding(8),
                                alignment: .bottomTrailing
                            )
                        }
                    }
                    .padding()
                }
                
                BottomNavBar(selectedTab: $router.currentTab) { screen in
                    router.switchTab(to: screen)
                }
            }
        }
        .photosPicker(isPresented: $isShowingPhotoPicker, selection: $selectedPhotoItems, maxSelectionCount: 0, matching: .images)
        .onChange(of: selectedPhotoItems) { _, newItems in
            Task {
                for newItem in newItems {
                    do {
                        if let data = try await newItem.loadTransferable(type: Data.self),
                           let image = UIImage(data: data) {
                            await MainActor.run {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                                    capturedImages.append(image)
                                }
                            }
                        } else {
                            await MainActor.run {
                                pickerError = "Could not load one of the selected images."
                            }
                        }
                    } catch {
                        await MainActor.run {
                            pickerError = "Failed to load a photo."
                        }
                    }
                }
                
                // Clear the selection
                await MainActor.run {
                    selectedPhotoItems = []
                }
            }
        }
        .alert("Camera", isPresented: Binding(
            get: { pickerError != nil },
            set: { show in
                if !show { pickerError = nil }
            }
        )) {
            Button("OK", role: .cancel) { pickerError = nil }
        } message: {
            Text(pickerError ?? "")
        }
        .navigationBarHidden(true)
    }
}

struct PetPhotosView_Preview: PreviewProvider {
    static var previews: some View {
        PetPhotosView().environmentObject(Router())
    }
}
